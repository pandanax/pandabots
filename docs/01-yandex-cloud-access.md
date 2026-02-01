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

Активный профиль: `pandanax`

Просмотр конфигурации:
```bash
yc config list
yc config profile list
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

# Создать ВМ
yc compute instance create \
  --name <name> \
  --zone ru-central1-b \
  --platform standard-v3 \
  --cores 2 \
  --memory 4 \
  --create-boot-disk image-folder-id=standard-images,image-family=ubuntu-2204-lts,size=20 \
  --network-interface subnet-name=default-ru-central1-b,nat-ip-version=ipv4 \
  --ssh-key ~/.ssh/id_rsa.pub

# Получить информацию о ВМ
yc compute instance get <instance-id>

# Запустить ВМ
yc compute instance start <instance-id>

# Остановить ВМ
yc compute instance stop <instance-id>

# Удалить ВМ
yc compute instance delete <instance-id>
```

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
