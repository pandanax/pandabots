# 🔄 Миграция на Managed PostgreSQL

> План миграции с Docker PostgreSQL на Yandex Managed PostgreSQL

**Дата:** 2026-02-01  
**Статус:** 📝 План готов к выполнению

---

## 🎯 Зачем миграция?

### Проблемы текущего решения (PostgreSQL в Docker):
❌ Нет автоматических бекапов  
❌ SSH недоступен - сложно управлять БД  
❌ Нужно вручную настраивать мониторинг  
❌ Нет высокой доступности  
❌ Обновления и патчи вручную

### Преимущества Managed PostgreSQL:
✅ **Автоматические бекапы** (7 дней retention)  
✅ **Управление через YC CLI** - без SSH!  
✅ **Встроенный мониторинг**  
✅ **Автоматические обновления**  
✅ **Высокая доступность** (опционально)  
✅ **SSL из коробки**  
✅ **Web SQL** - доступ через браузер

---

## 📊 Конфигурация нового кластера

**Параметры:**
- **Версия:** PostgreSQL 15
- **Ресурсы:** s2.micro (2 vCPU, 8 GB RAM)
- **Диск:** 10 GB SSD
- **Бекапы:** 7 дней
- **Стоимость:** ~3000-3500 руб/мес

**Итоговая стоимость проекта:**
- Managed PostgreSQL: ~3500 руб/мес
- ВМ n8n-server: ~6000 руб/мес
- **Итого:** ~9500 руб/мес

---

## ⚠️ ВАЖНО: Что будет потеряно при миграции

Если в текущей БД есть данные:
- ❌ **Workflows** (можно экспортировать через UI)
- ❌ **Credentials** (нужно пересоздать)
- ❌ **Executions history** (история выполнений)
- ❌ **История чата** в таблице `chat_history` (если есть)

**Решение:** Экспорт данных перед миграцией (см. ниже)

---

## 🛠️ План миграции

### Этап 1: Подготовка (10 мин)

1. **Экспортировать workflows из n8n UI:**
   - Открой https://n8n.mandala-app.online
   - Workflows → Export → Скачать JSON

2. **Сохранить список credentials:**
   - Скриншоты или запись всех credentials
   - Понадобятся для пересоздания

3. **Бекап данных PostgreSQL (опционально):**
   
   Если SSH доступен:
   ```bash
   ssh ubuntu@84.252.137.46
   cd /opt/n8n
   docker exec n8n-postgres pg_dump -U n8n n8n > /tmp/n8n_backup_$(date +%Y%m%d).sql
   docker cp n8n-postgres:/tmp/n8n_backup_*.sql ./
   ```
   
   Если SSH недоступен - используй Serial Console в Yandex Cloud Web Console

### Этап 2: Создание Managed PostgreSQL (15-20 мин)

1. **Применить Terraform:**
   ```bash
   cd terraform
   terraform init
   terraform plan
   # Проверь что создаётся:
   # - yandex_vpc_security_group.postgres_sg (доступы для ВМ)
   # - yandex_mdb_postgresql_cluster.n8n_postgres
   # - yandex_mdb_postgresql_database.n8n_db
   # - yandex_mdb_postgresql_user.n8n_user
   
   terraform apply
   ```
   
   ✅ **Доступы настроены автоматически!**  
   Terraform создаст Security Group для PostgreSQL с правилом:
   - Разрешён доступ с подсети ВМ n8n-server на порт 6432
   - ВМ сможет подключаться к PostgreSQL автоматически

2. **Получить connection string:**
   ```bash
   terraform output postgres_host
   terraform output -raw postgres_connection_string
   ```

3. **Проверить доступность кластера:**
   ```bash
   yc managed-postgresql cluster list --folder-id b1gmrr5e6bncvoin732o
   yc managed-postgresql cluster get <CLUSTER_ID>
   ```

### Этап 3: Обновление конфигурации n8n (5 мин)

1. **Обновить deploy/.env на сервере:**
   
   Через Serial Console или (если SSH работает):
   ```bash
   ssh ubuntu@84.252.137.46
   cd /opt/n8n
   
   # Бекап старого .env
   cp .env .env.backup
   
   # Обновить .env
   nano .env
   ```

2. **Добавить в .env:**
   ```bash
   # PostgreSQL Configuration (Yandex Managed PostgreSQL)
   DB_POSTGRESDB_HOST=c-XXXXX.rw.mdb.yandexcloud.net
   DB_POSTGRESDB_PORT=6432
   DB_POSTGRESDB_DATABASE=n8n
   DB_POSTGRESDB_USER=n8n
   DB_POSTGRESDB_PASSWORD=<PASSWORD_FROM_TERRAFORM_TFVARS>
   ```
   
   Получить host:
   ```bash
   cd terraform
   terraform output postgres_host
   ```

3. **Обновить docker-compose.yml:**
   
   Скопировать обновлённый файл на сервер:
   ```bash
   # Локально
   cd deploy
   scp docker-compose.yml ubuntu@84.252.137.46:/opt/n8n/
   ```

### Этап 4: Перезапуск n8n (5 мин)

1. **Остановить старые контейнеры:**
   ```bash
   cd /opt/n8n
   docker compose down
   ```

2. **Удалить старый PostgreSQL контейнер и volume (опционально):**
   ```bash
   docker volume ls
   docker volume rm n8n_postgres_data
   ```

3. **Запустить с новой конфигурацией:**
   ```bash
   docker compose up -d
   ```

4. **Проверить логи:**
   ```bash
   docker compose logs -f n8n
   # Должно быть: "Successfully connected to database"
   ```

### Этап 5: Восстановление данных (10-15 мин)

1. **Импортировать workflows:**
   - Открой https://n8n.mandala-app.online
   - Workflows → Import from File
   - Загрузи сохранённые JSON файлы

2. **Пересоздать credentials:**
   - Settings → Credentials
   - Создай заново все credentials
   - Обнови workflows чтобы использовали новые credentials

3. **Создать таблицу chat_history (для Mandala Bot):**
   ```bash
   yc managed-postgresql cluster execute --id <CLUSTER_ID> --database n8n --user n8n << 'EOF'
   CREATE TABLE IF NOT EXISTS chat_history (
       id SERIAL PRIMARY KEY,
       user_id BIGINT NOT NULL,
       role VARCHAR(20) NOT NULL,
       content TEXT NOT NULL,
       created_at TIMESTAMP NOT NULL DEFAULT NOW()
   );
   CREATE INDEX IF NOT EXISTS idx_user_created ON chat_history(user_id, created_at DESC);
   EOF
   ```

### Этап 6: Тестирование (10 мин)

1. **Проверить n8n:**
   - Открой https://n8n.mandala-app.online
   - Проверь что все workflows видны
   - Запусти тестовый workflow

2. **Проверить PostgreSQL:**
   ```bash
   # Список таблиц
   yc managed-postgresql cluster execute --id <CLUSTER_ID> --database n8n --user n8n -c "\dt"
   
   # Проверить подключение
   yc managed-postgresql cluster get <CLUSTER_ID>
   ```

3. **Проверить Telegram бота (если используется):**
   - Отправь тестовое сообщение
   - Проверь что бот отвечает

---

## 🔧 Управление через YC CLI

### Выполнение SQL запросов

```bash
# Базовый синтаксис
yc managed-postgresql cluster execute \
  --id <CLUSTER_ID> \
  --database n8n \
  --user n8n \
  --command "SELECT version();"

# Или короткая версия
yc managed-postgresql cluster execute \
  --id $(terraform output -raw postgres_cluster_id) \
  --database n8n \
  --user n8n \
  -c "SELECT COUNT(*) FROM chat_history;"
```

### Примеры команд

```bash
# Список таблиц
yc managed-postgresql cluster execute --id <CLUSTER_ID> --database n8n --user n8n -c "\dt"

# Последние записи в chat_history
yc managed-postgresql cluster execute --id <CLUSTER_ID> --database n8n --user n8n -c "SELECT * FROM chat_history ORDER BY created_at DESC LIMIT 10;"

# Статистика по пользователям
yc managed-postgresql cluster execute --id <CLUSTER_ID> --database n8n --user n8n << 'EOF'
SELECT user_id, COUNT(*) as messages 
FROM chat_history 
GROUP BY user_id 
ORDER BY messages DESC 
LIMIT 10;
EOF
```

### Управление кластером

```bash
# Информация о кластере
yc managed-postgresql cluster get <CLUSTER_ID>

# Список баз данных
yc managed-postgresql database list --cluster-id <CLUSTER_ID>

# Список пользователей
yc managed-postgresql user list --cluster-id <CLUSTER_ID>

# Бекапы
yc managed-postgresql backup list --cluster-id <CLUSTER_ID>

# Создать бекап вручную
yc managed-postgresql cluster backup <CLUSTER_ID>

# Мониторинг
yc managed-postgresql cluster list-logs --id <CLUSTER_ID> --limit 100
```

---

## 🆘 Troubleshooting

### Ошибка: "Cannot connect to PostgreSQL"

**Проверка:**
```bash
# Статус кластера
yc managed-postgresql cluster get <CLUSTER_ID> | grep status

# Должно быть: status: RUNNING
```

**Решение:**
- Проверь что кластер в статусе RUNNING
- Проверь что host правильный в .env
- Проверь пароль

### Ошибка: "SSL connection required"

**Решение:**
Добавь в .env:
```bash
DB_POSTGRESDB_SSL_ENABLED=true
DB_POSTGRESDB_SSL_REJECT_UNAUTHORIZED=false
```

### n8n не видит таблицы

**Проверка:**
```bash
yc managed-postgresql cluster execute --id <CLUSTER_ID> --database n8n --user n8n -c "\dt"
```

**Решение:**
- Пересоздай таблицы (см. Этап 5)
- Проверь права пользователя n8n

---

## 📚 Полезные ссылки

- [Yandex Managed PostgreSQL Docs](https://cloud.yandex.ru/docs/managed-postgresql/)
- [n8n Database Configuration](https://docs.n8n.io/hosting/configuration/configuration-methods/#database)
- [PostgreSQL 15 Documentation](https://www.postgresql.org/docs/15/)

---

## ✅ Чеклист миграции

Перед миграцией:
- [ ] Экспортировал все workflows из n8n
- [ ] Сохранил список всех credentials
- [ ] Создал бекап PostgreSQL (опционально)
- [ ] Проверил terraform.tfvars (пароль PostgreSQL)

Миграция:
- [ ] Применил terraform (создан кластер)
- [ ] Получил connection string из terraform output
- [ ] Обновил .env на сервере
- [ ] Обновил docker-compose.yml на сервере
- [ ] Перезапустил n8n

После миграции:
- [ ] n8n открывается и работает
- [ ] Импортировал workflows
- [ ] Пересоздал credentials
- [ ] Создал таблицу chat_history
- [ ] Протестировал Telegram бота
- [ ] Обновил документацию

---

**Статус:** 🟢 Готово к выполнению  
**Время выполнения:** ~1 час  
**Риск:** 🟡 Средний (нужно сохранить workflows)
