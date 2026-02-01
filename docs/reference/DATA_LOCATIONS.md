# 📍 Где какие данные - Полная карта

> Быстрая шпаргалка: где что лежит

## ✅ Данные ЕСТЬ и доступны локально

| Что | Где | В git? | Комментарий |
|-----|-----|--------|-------------|
| **Cloud ID** | `.local/quick-reference.md` | ❌ | b1gtthlctc244316ambs |
| **Folder ID** | `.local/quick-reference.md` | ❌ | b1gmrr5e6bncvoin732o |
| **Service Account ID** | `.local/quick-reference.md` | ❌ | ajefmtlpibd23o3ckhfl |
| **Server IP** | `.local/quick-reference.md` | ✅ | 84.252.137.46 (публичный) |
| **Domain** | `.local/quick-reference.md` | ✅ | n8n.mandala-app.online |
| **PostgreSQL Password** | `deploy/.env` | ❌ | y5TuS3PVKbMPGoAn5n7tXK7pgUZ0FQkI |
| **N8N Encryption Key** | `deploy/.env` | ❌ | 279bc3c... |
| **Terraform Config** | `terraform/terraform.tfvars` | ❌ | Полная конфигурация |
| **Service Account Key** | `~/.yc/n8n-sa-key.json` | ❌ | JSON ключ |

---

## 🗂️ Файлы с данными (НЕ в git)

### 1. `.local/` - Быстрый справочник
```
.local/
├── quick-reference.md       ← ВСЕ ДАННЫЕ ЗДЕСЬ!
├── project-config.env       ← Переменные окружения
└── README.md
```

**Читай для работы:**
```bash
cat .local/quick-reference.md
source .local/project-config.env
```

### 2. `terraform/terraform.tfvars` - Terraform
```
Cloud ID, Folder ID, пути к ключам, настройки VM
```

### 3. `deploy/.env` - Docker Compose
```
Пароли PostgreSQL, N8N encryption key
```

### 4. `~/.yc/` - Yandex Cloud
```
Service Account JSON ключ
```

---

## 🔍 Как найти данные

### Нужен Cloud ID?
```bash
cat .local/project-config.env | grep CLOUD_ID
# Или
cat terraform/terraform.tfvars | grep cloud_id
```

### Нужен Folder ID?
```bash
cat .local/project-config.env | grep FOLDER_ID
# Или
cat terraform/terraform.tfvars | grep folder_id
```

### Нужны пароли?
```bash
cat deploy/.env | grep PASSWORD
cat deploy/.env | grep ENCRYPTION_KEY
```

### Нужна вся информация?
```bash
cat .local/quick-reference.md
```

---

## 🛡️ Защита

Все эти файлы в `.gitignore`:

```bash
# Проверь что не попадут в git:
git status
git ls-files | grep -E "\.local|terraform\.tfvars|\.env$"
# Должно быть пусто!
```

---

## 🤖 Для AI агента

**Когда нужны данные для команд:**

```bash
# 1. Прочитай конфиг
source .local/project-config.env

# 2. Используй переменные
yc compute instance list --folder-id $FOLDER_ID
ssh $SSH_USER@$SERVER_IP

# 3. Или читай напрямую
CLOUD_ID=$(grep CLOUD_ID .local/project-config.env | cut -d= -f2)
```

**Помни:**
- ✅ Можно читать и использовать все файлы
- ✅ Можно показывать Cloud ID, Folder ID, IP
- ❌ НЕ показывай пароли и encryption keys!
- ❌ НЕ показывай содержимое Service Account JSON!

---

## 📦 Итого

Все критические данные сохранены в:

1. ✅ `.local/quick-reference.md` - **ВСЁ В ОДНОМ МЕСТЕ**
2. ✅ `.local/project-config.env` - переменные окружения
3. ✅ `terraform/terraform.tfvars` - Terraform конфигурация
4. ✅ `deploy/.env` - Docker Compose секреты
5. ✅ `~/.yc/n8n-sa-key.json` - Service Account ключ

**Ни один из этих файлов не попадёт в git!**

Но все доступны локально для работы! ✅

---

**См. также:** [LOCAL_DATA_GUIDE.md](LOCAL_DATA_GUIDE.md) для подробностей
