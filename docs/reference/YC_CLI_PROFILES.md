# 🔑 YC CLI Профили - Быстрый Справочник

> **Для AI агентов:** Читай это если нужно подключиться к VM или работать с YC CLI

**Дата:** 2026-02-01

---

## ⚡ Быстрая шпаргалка

```bash
# Для SSH к VM (OS Login)
yc config profile activate pandanax && yc compute ssh --name n8n-server

# Для Terraform
yc config profile activate sa-n8n-bot && cd terraform && terraform apply

# Проверить текущий профиль
yc config profile list  # ACTIVE = текущий
```

---

## 📋 Два профиля в проекте

| Характеристика | `pandanax` | `sa-n8n-bot` |
|----------------|------------|--------------|
| **Тип** | Личный OAuth аккаунт | Service Account |
| **Идентификация** | `token: y0_...` | `service-account-key: id: ajef...` |
| **Email** | pandanax.ya@yandex.ru | n8n-bot (no email) |
| **User/SA ID** | ajejr683b02rpq8g46jk | ajefmtlpibd23o3ckhfl |
| **OS Login роль** | `compute.osAdminLogin` ✅ | `compute.osLogin` ✅ |
| **SSH ключ в OS Login** | ✅ Есть (id_ed25519) | ❌ Нет |
| **Может SSH к VM** | ✅ ДА | ❌ НЕТ |
| **Может Terraform** | ✅ ДА | ✅ ДА (рекомендуется) |

---

## 🎯 Когда использовать какой профиль

### Используй `pandanax` для:

✅ SSH подключения к VM через OS Login
```bash
yc config profile activate pandanax
yc compute ssh --name n8n-server
```

✅ Любые интерактивные команды на VM
```bash
yc compute ssh --name n8n-server -- "docker compose ps"
```

✅ Работа с OS Login (добавление ключей, проверка доступа)
```bash
yc organization-manager oslogin user-ssh-key list \
  --organization-id bpfbiscmjngo5cdheuhg \
  --subject-id ajejr683b02rpq8g46jk
```

### Используй `sa-n8n-bot` для:

✅ Terraform операций (рекомендуется для автоматизации)
```bash
yc config profile activate sa-n8n-bot
cd terraform && terraform apply
```

✅ Автоматизированных скриптов
✅ CI/CD пайплайнов (в будущем)

### Оба профиля могут:

✅ Работать с Yandex Cloud ресурсами (VM, networks, DNS, PostgreSQL)
✅ Читать конфигурацию и статус ресурсов
✅ Работать с Managed PostgreSQL через `yc managed-postgresql`

---

## 🔍 Как проверить текущий профиль

### Метод 1: Список профилей
```bash
yc config profile list

# Вывод:
# default
# pandanax
# personal
# sa-n8n-bot ACTIVE  ← это текущий профиль
```

### Метод 2: Конфигурация профиля
```bash
yc config list

# Если видишь:
# token: y0_...                    → это pandanax
# service-account-key: id: ajef... → это sa-n8n-bot
```

---

## 🔄 Переключение профилей

### Переключиться и выполнить команду

```bash
# Для SSH
yc config profile activate pandanax && yc compute ssh --name n8n-server

# Для Terraform
yc config profile activate sa-n8n-bot && terraform plan

# Проверить и переключиться если нужно
yc config profile list && yc config profile activate pandanax
```

### Постоянное переключение

```bash
# Переключиться на pandanax (останется активным)
yc config profile activate pandanax

# Все последующие команды используют pandanax
yc compute ssh --name n8n-server
yc compute instance list
yc organization-manager user list
```

---

## ⚠️ Типичные ошибки и решения

### Ошибка 1: "OS login info not found for subject 'ajefmtlpibd23o3ckhfl'"

**Что произошло:** Пытаешься SSH с профилем `sa-n8n-bot`

**Почему:** Service account не имеет SSH ключа в OS Login

**Решение:**
```bash
yc config profile activate pandanax
yc compute ssh --name n8n-server
```

### Ошибка 2: "Permission denied (publickey)"

**Что произошло:** SSH ключ не добавлен в OS Login или не та роль

**Проверь:**
```bash
# 1. Правильный ли профиль?
yc config profile list  # должен быть pandanax ACTIVE

# 2. Есть ли роль OS Login?
yc organization-manager organization list-access-bindings bpfbiscmjngo5cdheuhg | grep ajejr683b02rpq8g46jk

# 3. Есть ли SSH ключ?
yc organization-manager oslogin user-ssh-key list \
  --organization-id bpfbiscmjngo5cdheuhg \
  --subject-id ajejr683b02rpq8g46jk
```

### Ошибка 3: "You do not have permission" (при terraform)

**Что произошло:** Недостаточно прав

**Решение:** Оба профиля имеют role `editor` на folder, должно работать. Проверь:
```bash
yc config list  # проверить что folder_id правильный
```

---

## 📊 Сравнительная таблица команд

| Задача | Команда |
|--------|---------|
| **Подключиться к VM** | `yc config profile activate pandanax && yc compute ssh --name n8n-server` |
| **Выполнить команду на VM** | `yc config profile activate pandanax && yc compute ssh --name n8n-server -- "команда"` |
| **Terraform plan** | `yc config profile activate sa-n8n-bot && terraform plan` |
| **Terraform apply** | `yc config profile activate sa-n8n-bot && terraform apply` |
| **Список VM** | Любой профиль: `yc compute instance list` |
| **PostgreSQL запросы** | Любой профиль: `yc managed-postgresql cluster execute --id $CLUSTER_ID ...` |
| **Проверить текущий профиль** | `yc config profile list` |
| **Посмотреть конфигурацию** | `yc config list` |

---

## 🎓 Для AI агента: Алгоритм действий

### Если нужно подключиться к VM:

1. **СНАЧАЛА** переключись на `pandanax`:
   ```bash
   yc config profile activate pandanax
   ```

2. **ЗАТЕМ** выполни SSH команду:
   ```bash
   yc compute ssh --name n8n-server
   ```

3. **ИЛИ** одной строкой:
   ```bash
   yc config profile activate pandanax && yc compute ssh --name n8n-server
   ```

### Если видишь ошибку "OS login info not found":

1. Проверь активный профиль:
   ```bash
   yc config profile list
   ```

2. Если активен `sa-n8n-bot` → переключись на `pandanax`:
   ```bash
   yc config profile activate pandanax
   ```

3. Попробуй снова:
   ```bash
   yc compute ssh --name n8n-server
   ```

### Если работаешь с Terraform:

1. Можешь использовать любой профиль, но лучше `sa-n8n-bot`:
   ```bash
   yc config profile activate sa-n8n-bot
   ```

2. Выполни terraform команды:
   ```bash
   cd terraform && terraform plan
   ```

---

## 📚 Полезные ссылки

- **Полный гайд по OS Login:** [OS_LOGIN_GUIDE.md](../guides/OS_LOGIN_GUIDE.md)
- **Доступ к Yandex Cloud:** [../01-yandex-cloud-access.md](../01-yandex-cloud-access.md)
- **Быстрый старт:** [../guides/QUICK_START.md](../guides/QUICK_START.md)

---

**Автор:** AI Agent  
**Создано:** 2026-02-01  
**Обновлено:** 2026-02-01 20:50 UTC+3
