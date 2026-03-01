# 🔐 Сетевые доступы и Security Groups

> Как настроены доступы между компонентами проекта

**Обновлено:** 2026-02-01

---

## 📊 Архитектура сети

```
┌─────────────────────────────────────────────────────────┐
│  Yandex VPC: n8n-network                                │
│                                                           │
│  ┌─────────────────────────────────────────────────┐    │
│  │  Subnet: n8n-subnet (10.128.0.0/24)            │    │
│  │                                                  │    │
│  │  ┌──────────────────┐    ┌─────────────────┐  │    │
│  │  │ ВМ: n8n-server   │───▶│  PostgreSQL     │  │    │
│  │  │ 10.128.0.14      │    │  Managed        │  │    │
│  │  │                  │    │  Cluster        │  │    │
│  │  │ Security Group:  │    │                 │  │    │
│  │  │ - SSH: 22        │    │  Security Group:│  │    │
│  │  │ - HTTP: 80       │    │  - Port 6432    │  │    │
│  │  │ - HTTPS: 443     │    │    from subnet  │  │    │
│  │  └──────────────────┘    └─────────────────┘  │    │
│  └─────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────┘
         ▲                               
         │ (через NAT)
         │
    Internet
```

---

## 🛡️ Security Groups

### 1. Security Group для ВМ (`n8n-security-group`)

**Файл:** `terraform/security.tf`

**Входящий трафик (Ingress):**
- ✅ SSH (22) - с любого IP (0.0.0.0/0)
  - Защищен: Fail2ban
- ✅ HTTP (80) - с любого IP
  - Для Let's Encrypt ACME challenge
- ✅ HTTPS (443) - с любого IP
  - Основной доступ к n8n

**Исходящий трафик (Egress):**
- ✅ Любой (ALL) - куда угодно
  - Нужен для: обновлений Docker образов, подключения к Managed PostgreSQL, внешних API

### 2. Security Group для PostgreSQL (`postgres-security-group`)

**Файл:** `terraform/postgresql.tf`

**Входящий трафик (Ingress):**
- ✅ PostgreSQL (6432) - ТОЛЬКО из подсети n8n-subnet (10.128.0.0/24)
  - Разрешает доступ только для ВМ n8n-server
  - Никто другой не может подключиться

**Исходящий трафик (Egress):**
- ✅ Любой (ALL) - куда угодно

---

## 🔌 Как ВМ подключается к PostgreSQL

### 1. Внутренняя сеть

ВМ и PostgreSQL находятся в **одной подсети** (n8n-subnet):
- ВМ: `10.128.0.14`
- PostgreSQL: получает внутренний IP автоматически
- Подключение идёт через **внутреннюю сеть Yandex Cloud**
- Не тратит внешний трафик
- Низкая латентность

### 2. Security Group разрешает доступ

Terraform создаёт правило:

```hcl
# Доступ из ВМ n8n-server к PostgreSQL
ingress {
  protocol       = "TCP"
  description    = "PostgreSQL from n8n VM"
  port           = 6432
  v4_cidr_blocks = [yandex_vpc_subnet.n8n_subnet.v4_cidr_blocks[0]]
}
```

**Что это значит:**
- Протокол: TCP
- Порт: 6432 (Managed PostgreSQL pooler)
- Откуда: вся подсеть n8n-subnet (10.128.0.0/24)
- Результат: ВМ может подключиться к PostgreSQL

### 3. SSL подключение

n8n подключается к PostgreSQL с SSL:

```env
DB_POSTGRESDB_HOST=c-xxxxxxxxx.rw.mdb.yandexcloud.net
DB_POSTGRESDB_PORT=6432
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false
```

---

## ✅ Проверка доступа

### Из ВМ к PostgreSQL

После деплоя можно проверить:

```bash
# На ВМ n8n-server (если SSH доступен)
nc -zv c-xxxxxxxxx.rw.mdb.yandexcloud.net 6432

# Должно быть:
# Connection to c-xxxxxxxxx.rw.mdb.yandexcloud.net 6432 port [tcp/*] succeeded!
```

### Из n8n контейнера

```bash
# Проверка логов n8n
docker logs n8n | grep -i "database\|connect"

# Должно быть:
# Successfully connected to database
```

### Через YC CLI

```bash
# Информация о кластере
yc managed-postgresql cluster get $(terraform output -raw postgres_cluster_id)

# Должно показать статус: RUNNING
```

---

## 🚫 Что НЕ имеет доступа

### Нельзя подключиться к PostgreSQL:

❌ **С интернета напрямую**
  - PostgreSQL не имеет публичного IP
  - Только через внутреннюю сеть

❌ **С других подсетей**
  - Security Group разрешает только n8n-subnet

❌ **С других ВМ в той же подсети**
  - Технически могут, но нет credentials

### Исключения:

✅ **Yandex Cloud Console (Web SQL)**
  - Настроено через `access { web_sql = true }`
  - Доступ через веб-интерфейс Yandex Cloud

✅ **YC CLI**
  - Команды `yc managed-postgresql cluster execute`
  - Использует сервисный аккаунт

---

## 🔧 Изменение доступов

### Разрешить доступ с другой подсети

Отредактируй `terraform/postgresql.tf`:

```hcl
resource "yandex_vpc_security_group" "postgres_sg" {
  # ...
  
  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL from another subnet"
    port           = 6432
    v4_cidr_blocks = ["10.129.0.0/24"]  # другая подсеть
  }
}
```

### Разрешить доступ с конкретного IP

```hcl
ingress {
  protocol       = "TCP"
  description    = "PostgreSQL from specific IP"
  port           = 6432
  v4_cidr_blocks = ["203.0.113.5/32"]  # конкретный IP
}
```

### Применить изменения

```bash
cd terraform
terraform plan
terraform apply
```

---

## 🔍 Troubleshooting

### Ошибка: "Connection timeout"

**Причина:** Security Group не разрешает доступ

**Решение:**
```bash
# Проверить security group
yc vpc security-group get $(terraform output -raw postgres_security_group_id)

# Проверить что правило для n8n-subnet есть
```

### Ошибка: "SSL connection required"

**Причина:** PostgreSQL требует SSL, но n8n не настроен

**Решение:** Добавь в `.env`:
```env
DB_POSTGRESDB_SSL_ENABLED=true
```

### Ошибка: "Authentication failed"

**Причина:** Неправильный пароль или пользователь

**Решение:**
```bash
# Проверить пароль
cat terraform/terraform.tfvars | grep postgres_password

# Проверить пользователя
yc managed-postgresql user list --cluster-id $(terraform output -raw postgres_cluster_id)
```

---

## 📚 Полезные команды

```bash
# Информация о security group ВМ
yc vpc security-group get $(yc compute instance get n8n-server --format json | jq -r '.network_interfaces[0].security_group_ids[0]')

# Информация о security group PostgreSQL
yc vpc security-group get $(terraform output -raw postgres_security_group_id)

# Информация о подсети
yc vpc subnet get n8n-subnet

# Список всех security groups в сети
yc vpc security-group list --network-name n8n-network
```

---

## 🔗 Ссылки

- [Yandex Cloud Security Groups](https://cloud.yandex.ru/docs/vpc/concepts/security-groups)
- [Managed PostgreSQL Network Settings](https://cloud.yandex.ru/docs/managed-postgresql/concepts/network)
- [Terraform Yandex Security Group](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/vpc_security_group)

---

**Статус:** ✅ Доступы настроены  
**Автор:** AI Agent  
**Дата:** 2026-02-01
