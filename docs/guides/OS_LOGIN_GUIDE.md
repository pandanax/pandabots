# 🔐 OS Login: Централизованный доступ через SSH

> Как настроен и работает OS Login в проекте n8n

**Статус:** ✅ Настроено и работает  
**Обновлено:** 2026-02-01

---

## 📖 Что такое OS Login?

OS Login — это централизованная система управления SSH-доступом через Yandex Cloud IAM.

**Преимущества:**
- ✅ Управление доступом через IAM (роли и права)
- ✅ Не нужно manually управлять SSH ключами на серверах
- ✅ Автоматическое создание пользователей при первом подключении
- ✅ Audit логи всех подключений
- ✅ Подключение через `yc compute ssh` без указания IP

**Как это работает:**
1. Пользователь получает роль `compute.osLogin` или `compute.osAdminLogin` в организации
2. Пользователь добавляет свой SSH ключ в OS Login профиль
3. При подключении через `yc compute ssh`:
   - YC CLI генерирует временный сертификат
   - На VM агент OS Login проверяет права пользователя
   - Создается пользователь (если нужно) и разрешается доступ

---

## 🎯 Текущая конфигурация

### Роли OS Login

| Пользователь / SA | Тип | Роль | Доступ |
|-------------------|-----|------|--------|
| `pandanax-ya` (ajejr683b02rpq8g46jk) | User | `compute.osAdminLogin` | SSH + sudo |
| `n8n-bot` (ajefmtlpibd23o3ckhfl) | Service Account | `compute.osLogin` | SSH only |

### VM Configuration

**VM:** `n8n-server` (epd1hs0nht8o2bf48b65)

**Metadata:**
```yaml
enable-oslogin: true
serial-port-enable: "1"
```

**Установленные пакеты:**
- `google-compute-engine-oslogin` - основной агент OS Login
- `google-guest-agent` - агент для работы с Yandex Cloud

**Конфигурация:**
- NSS: `/etc/nsswitch.conf` - добавлены модули `cache_oslogin` и `oslogin`
- SSH: `/etc/ssh/sshd_config.d/99-google-oslogin.conf` - настроен `AuthorizedKeysCommand`
- PAM: `/etc/pam.d/sshd` - добавлены модули `pam_oslogin_login.so` и `pam_oslogin_admin.so`
- Sudoers: `/etc/sudoers` - включена директория `/var/google-sudoers.d/`

---

## 🚀 Как использовать OS Login

### ⚠️ ВАЖНО: YC CLI Профили

В проекте настроены два профиля YC CLI:

| Профиль | Может подключаться по SSH? | Почему? |
|---------|---------------------------|---------|
| **`pandanax`** | ✅ ДА | Личный аккаунт, есть роль `compute.osAdminLogin` и SSH ключ |
| **`sa-n8n-bot`** | ❌ НЕТ | Service account, нет SSH ключа в OS Login |

**ПРАВИЛО:** Для SSH **ВСЕГДА используй профиль `pandanax`**!

### Подключение к серверу

```bash
# 1. СНАЧАЛА переключись на правильный профиль!
yc config profile activate pandanax

# 2. Теперь подключайся
yc compute ssh --name n8n-server

# Или одной командой
yc config profile activate pandanax && yc compute ssh --name n8n-server
```

### Выполнение команд

```bash
# Проверить текущий профиль
yc config profile list  # ACTIVE = текущий профиль

# Переключиться и выполнить команду
yc config profile activate pandanax
yc compute ssh --name n8n-server -- whoami

# По ID VM
yc compute ssh --id epd1hs0nht8o2bf48b65 -- "echo 'Hello!'"
```

### Проверка доступа

```bash
# Проверить свой OS Login профиль
yc organization-manager oslogin user-ssh-key list \
  --organization-id bpfbiscmjngo5cdheuhg \
  --subject-id $(yc iam user-account get --login $(yc config get login) --format json | jq -r .id)

# Проверить роли OS Login
yc organization-manager organization list-access-bindings bpfbiscmjngo5cdheuhg | grep osLogin

# Тест подключения
yc compute ssh --name n8n-server -- "whoami && sudo whoami"
```

### Добавление SSH ключа

**Для себя:**
```bash
# Получить свой user ID
USER_ID=$(yc organization-manager user list --organization-id bpfbiscmjngo5cdheuhg | grep $(yc config get login) | awk '{print $2}')

# Добавить ключ
yc organization-manager oslogin user-ssh-key create \
  --organization-id bpfbiscmjngo5cdheuhg \
  --subject-id $USER_ID \
  --name "my-macbook" \
  --data "$(cat ~/.ssh/id_ed25519.pub)"
```

**Для другого пользователя:**
```bash
yc organization-manager oslogin user-ssh-key create \
  --organization-id bpfbiscmjngo5cdheuhg \
  --subject-id <USER_ID> \
  --name "user-laptop" \
  --data "<SSH_PUBLIC_KEY>"
```

---

## 👥 Добавление нового пользователя

### 1. Дать роль OS Login

**Обычный пользователь (SSH only):**
```bash
yc organization-manager organization add-access-binding bpfbiscmjngo5cdheuhg \
  --role compute.osLogin \
  --subject userAccount:<USER_ID>
```

**Админ (SSH + sudo):**
```bash
yc organization-manager organization add-access-binding bpfbiscmjngo5cdheuhg \
  --role compute.osAdminLogin \
  --subject userAccount:<USER_ID>
```

**Service Account:**
```bash
yc organization-manager organization add-access-binding bpfbiscmjngo5cdheuhg \
  --role compute.osLogin \
  --subject serviceAccount:<SA_ID>
```

### 2. Добавить в Terraform

Отредактируй `terraform/oslogin.tf`:

```hcl
variable "oslogin_admin_users" {
  description = "List of user IDs for OS Login admin access (with sudo)"
  type        = list(string)
  default     = [
    "ajejr683b02rpq8g46jk",  # pandanax-ya
    "<NEW_USER_ID>",          # новый пользователь
  ]
}
```

Примени изменения:
```bash
cd terraform
terraform plan
terraform apply
```

### 3. Пользователь добавляет SSH ключ

Пользователь должен сам добавить свой публичный SSH ключ (см. выше).

---

## 🔍 Troubleshooting

### Ошибка: "OS login info not found for subject 'ajefmtlpibd23o3ckhfl'"

**Причина:** Активен неправильный профиль YC CLI (service account `sa-n8n-bot`)

**Решение:**
```bash
# Проверить какой профиль активен
yc config profile list
# Если активен sa-n8n-bot → переключись на pandanax

# Переключиться на личный профиль
yc config profile activate pandanax

# Теперь подключайся
yc compute ssh --name n8n-server
```

### Ошибка: "OS login info not found" (для другого пользователя)

**Причина:** У пользователя нет роли OS Login

**Решение:**
```bash
# Проверить роли
yc organization-manager organization list-access-bindings bpfbiscmjngo5cdheuhg | grep <USER_ID>

# Дать роль
yc organization-manager organization add-access-binding bpfbiscmjngo5cdheuhg \
  --role compute.osAdminLogin \
  --subject userAccount:<USER_ID>
```

### Ошибка: "Permission denied (publickey)"

**Причина:** SSH ключ не добавлен в OS Login профиль

**Решение:**
```bash
# Проверить ключи
yc organization-manager oslogin user-ssh-key list \
  --organization-id bpfbiscmjngo5cdheuhg \
  --subject-id <USER_ID>

# Добавить ключ
yc organization-manager oslogin user-ssh-key create \
  --organization-id bpfbiscmjngo5cdheuhg \
  --subject-id <USER_ID> \
  --name "my-key" \
  --data "$(cat ~/.ssh/id_ed25519.pub)"
```

### Ошибка: "Invalid user"

**Причина:** Агент OS Login не установлен или не настроен на VM

**Решение:**
```bash
# Подключиться через Serial Console или обычный SSH
ssh ubuntu@<VM_IP>

# Проверить пакет
dpkg -l | grep google-compute-engine-oslogin

# Проверить сервис
sudo systemctl status google-oslogin-cache.service

# Проверить NSS
cat /etc/nsswitch.conf | grep oslogin

# Если нет - переразвернуть VM через terraform apply
```

### Sudo требует пароль

**Причина:** Директория `/var/google-sudoers.d/` не включена в sudoers

**Решение:**
```bash
ssh ubuntu@<VM_IP>
sudo grep -q google-sudoers.d /etc/sudoers || sudo bash -c 'echo "#includedir /var/google-sudoers.d" >> /etc/sudoers'
```

### VM была пересоздана и OS Login перестал работать

**Причина:** Новая VM не имеет конфигурации OS Login

**Решение:** Переразвернуть через Terraform (cloud-init автоматически настроит OS Login):
```bash
cd terraform
terraform taint yandex_compute_instance.n8n_vm
terraform apply
```

---

## 🔧 Ручная настройка OS Login (для reference)

Если нужно настроить OS Login на существующей VM вручную:

### 1. Установить пакеты
```bash
sudo apt update
sudo apt install -y google-compute-engine-oslogin
```

### 2. Создать директории
```bash
sudo mkdir -p /var/google-users.d /var/google-sudoers.d
sudo chmod 755 /var/google-users.d /var/google-sudoers.d
```

### 3. Настроить NSS
```bash
sudo sed -i 's/^\(passwd:.*\)$/\1 cache_oslogin oslogin/' /etc/nsswitch.conf
sudo sed -i 's/^\(group:.*\)$/\1 cache_oslogin oslogin/' /etc/nsswitch.conf
```

### 4. Настроить SSH
```bash
sudo bash -c 'cat > /etc/ssh/sshd_config.d/99-google-oslogin.conf <<EOF
# Google OS Login configuration
AuthorizedKeysCommand /usr/bin/google_authorized_keys %u
AuthorizedKeysCommandUser root
EOF'
```

### 5. Настроить PAM
```bash
sudo bash -c 'cat >> /etc/pam.d/sshd <<EOF

# Google OS Login
auth       [success=done perm_denied=die default=ignore] pam_oslogin_login.so
auth       [success=done perm_denied=die default=ignore] pam_oslogin_admin.so
account    [success=ok default=ignore] pam_oslogin_login.so
account    [success=ok default=ignore] pam_oslogin_admin.so
session    [success=ok default=ignore] pam_mkhomedir.so
EOF'
```

### 6. Настроить sudoers
```bash
sudo bash -c 'echo "#includedir /var/google-sudoers.d" >> /etc/sudoers'
```

### 7. Перезапустить SSH
```bash
sudo systemctl restart sshd
```

### 8. Обновить metadata VM
```bash
yc compute instance update <VM_ID> --metadata enable-oslogin=true
```

---

## 📚 Полезные команды

```bash
# Список пользователей организации
yc organization-manager user list --organization-id bpfbiscmjngo5cdheuhg

# Список всех ролей OS Login
yc organization-manager organization list-access-bindings bpfbiscmjngo5cdheuhg | grep osLogin

# Список VM с OS Login
yc compute instance list --format json | jq -r '.[] | select(.metadata."enable-oslogin" == "true") | .name'

# Удалить SSH ключ из OS Login
yc organization-manager oslogin user-ssh-key delete <KEY_ID>

# Отозвать роль OS Login
yc organization-manager organization remove-access-binding bpfbiscmjngo5cdheuhg \
  --role compute.osLogin \
  --subject userAccount:<USER_ID>
```

---

## 🔗 Ссылки

- [Yandex Cloud: OS Login](https://cloud.yandex.ru/docs/compute/operations/vm-connect/os-login)
- [Yandex Cloud: IAM Roles](https://cloud.yandex.ru/docs/iam/concepts/access-control/roles)
- [Terraform: OS Login IAM](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/organization_manager_organization_iam_member)

---

**Автор:** AI Agent  
**Дата создания:** 2026-02-01  
**Последнее обновление:** 2026-02-01
