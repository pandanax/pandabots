# Yandex Cloud: Доступ и авторизация

## Обзор

Документация для AI агента по работе с Yandex Cloud через CLI `yc`.
Проект развернут в облаке Yandex Cloud, используем Service Account для автоматизации.

## Параметры облака

```yaml
Cloud: your-cloud-name
Cloud ID: <получить через: yc config list>

Folder: n8n
Folder ID: <получить через: yc config list>

Zone: ru-central1-b
Region: ru-central1
```

## Service Account

```yaml
Name: n8n-bot
ID: <service account ID>
Description: Service account for AI agent automation
Role: editor (на каталог n8n)

Authorized Key:
  Key ID: <authorized key ID>
  Algorithm: RSA_2048
  Location: ~/.yc/n8n-sa-key.json
```

## Профили yc CLI

В проекте настроены **два профиля**:

| Профиль | Тип | Когда использовать |
|---------|-----|-------------------|
| **`pandanax`** | Личный OAuth | ✅ SSH к VM (OS Login), интерактивные команды |
| **`sa-n8n-bot`** | Service Account | ✅ Terraform, автоматизация, скрипты |

### Переключение между профилями

```bash
# Посмотреть список профилей (ACTIVE = текущий)
yc config profile list

# Переключиться на личный (для SSH)
yc config profile activate pandanax

# Переключиться на service account (для Terraform)
yc config profile activate sa-n8n-bot

# Проверить текущий профиль
yc config list
```

### Правила использования

**Для SSH к VM через OS Login:**
- ⚠️ **ОБЯЗАТЕЛЬНО** используй профиль `pandanax`
- Service account не может подключиться (нет SSH ключа в OS Login)
- Перед любой SSH командой: `yc config profile activate pandanax`

**Для Terraform операций:**
- Можно использовать `sa-n8n-bot` (рекомендуется) или `pandanax`
- Service account - это правильная практика для автоматизации

**Пример:**
```bash
# SSH - используй pandanax
yc config profile activate pandanax
yc compute ssh --name n8n-server

# Terraform - используй sa-n8n-bot
yc config profile activate sa-n8n-bot
cd terraform && terraform apply
```

## Авторизация для AI агента

### Через Service Account (рекомендуется)

Service Account создан для автоматизации без интерактивного доступа.
Используется авторизованный ключ (authorized key) в формате JSON.

Ключ хранится в: `~/.yc/n8n-sa-key.json` (не коммитится в git)

### Активация Service Account

```bash
yc config profile create sa-n8n-bot
yc config set service-account-key ~/.yc/n8n-sa-key.json
yc config set cloud-id b1gtthlctc244316ambs
yc config set folder-id b1gmrr5e6bncvoin732o
```

## Проверка доступа

```bash
# Переключиться на профиль Service Account
yc config profile activate sa-n8n-bot

# Проверить текущую конфигурацию
yc config list

# Проверить доступ к облаку
yc resource-manager cloud list

# Проверить доступ к каталогу
yc resource-manager folder list

# Проверить доступ к Compute
yc compute instance list
```

## Основные команды для работы с виртуальными машинами

```bash
# Список ВМ
yc compute instance list

# Подключение к ВМ через OS Login
yc compute ssh --name n8n-server
yc compute ssh --id <instance-id>

# Выполнение команды на ВМ
yc compute ssh --name n8n-server -- "command"

# Получить информацию о ВМ
yc compute instance get <instance-id>

# Запустить ВМ
yc compute instance start <instance-id>

# Остановить ВМ
yc compute instance stop <instance-id>

# Перезагрузить ВМ
yc compute instance restart <instance-id>

# Удалить ВМ
yc compute instance delete <instance-id>
```

## OS Login

В проекте настроен **OS Login** для централизованного управления SSH доступом.

**Что это дает:**
- Подключение через `yc compute ssh` без знания IP адреса
- Управление доступом через IAM роли
- Автоматическое создание пользователей
- Audit логи подключений

**Команды OS Login:**

```bash
# Список пользователей с OS Login доступом
yc organization-manager organization list-access-bindings <org-id> | grep osLogin

# Добавить SSH ключ для OS Login
yc organization-manager oslogin user-ssh-key create \
  --organization-id <org-id> \
  --subject-id <user-id> \
  --name "my-laptop" \
  --data "$(cat ~/.ssh/id_ed25519.pub)"

# Список SSH ключей
yc organization-manager oslogin user-ssh-key list \
  --organization-id <org-id> \
  --subject-id <user-id>
```

**Подробнее:** См. [OS_LOGIN_GUIDE.md](guides/OS_LOGIN_GUIDE.md)

## Примечания

- OAuth токены истекают и требуют периодической переавторизации через браузер
- Service Account подходит для автоматизации и долгосрочной работы
- Авторизованные ключи не истекают (пока не удалены)
- Для безопасности ключи хранятся вне репозитория

## Статус настройки

✅ Service Account создан (n8n-bot)
✅ Авторизованный ключ создан и сохранен
✅ Профиль `sa-n8n-bot` настроен и активирован
✅ Доступ к Compute API проверен и работает
✅ AI агент может выполнять команды в терминале
✅ AI агент может работать с yc CLI напрямую

## Следующие шаги документации

- [ ] Документировать создание и управление виртуальными машинами
- [ ] Документировать работу с сетями (VPC, подсети)
- [ ] Документировать работу с дисками
- [ ] Документировать работу с Object Storage
- [ ] Документировать работу с Container Registry
