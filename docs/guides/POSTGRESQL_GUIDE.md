# 🗄️ Руководство по работе с PostgreSQL

> Как работать с PostgreSQL на сервере n8n через Yandex Cloud CLI

---

## ⚠️ ВАЖНО: Используй YC CLI!

SSH порт 22 может быть заблокирован провайдером/VPN/файрволом. Поэтому все операции выполняются через **Yandex Cloud CLI**.

### Базовая команда

```bash
yc compute ssh --name n8n-server --command "ВАША_КОМАНДА"
```

---

## 🔍 Проверка подключения

### Проверить что PostgreSQL запущен

```bash
# Проверка статуса контейнера
yc compute ssh --name n8n-server --command "docker ps | grep postgres"

# Проверка здоровья PostgreSQL
yc compute ssh --name n8n-server --command "docker exec n8n-postgres pg_isready -U n8n"

# Версия PostgreSQL
yc compute ssh --name n8n-server --command "docker exec n8n-postgres psql -U n8n -d n8n -c 'SELECT version();'"
```

Ожидаемый результат:
```
n8n-postgres/var/lib/postgresql/data
```

---

## 📋 Основные операции

### Список таблиц

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c '\dt'
"
```

### Структура конкретной таблицы

```bash
# Например, для таблицы chat_history
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c '\d chat_history'
"
```

### Список индексов

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c '\di'
"
```

---

## 🆕 Создание таблицы chat_history

### Для Mandala Bot (история диалогов)

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_created ON chat_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_id ON chat_history(user_id);

-- Проверка
SELECT 'Table chat_history created successfully!' as status;
\dt chat_history
EOF
"
```

### Проверить что таблица создана

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c '\d chat_history'
"
```

---

## 📊 Работа с данными

### Просмотр данных

```bash
# Количество записей
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'SELECT COUNT(*) FROM chat_history;'
"

# Последние 10 сообщений
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'SELECT id, user_id, role, LEFT(content, 50) as content_preview, created_at FROM chat_history ORDER BY created_at DESC LIMIT 10;'
"

# Сообщения конкретного пользователя
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'SELECT * FROM chat_history WHERE user_id = 123456789 ORDER BY created_at DESC;'
"
```

### Вставка тестовых данных

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
INSERT INTO chat_history (user_id, role, content) VALUES
  (123456789, 'user', 'Привет!'),
  (123456789, 'assistant', 'Здравствуй! Как дела?');
EOF
"
```

### Обновление данных

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c \"UPDATE chat_history SET content = 'Новый текст' WHERE id = 1;\"
"
```

### Удаление данных

```bash
# Удалить конкретную запись
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'DELETE FROM chat_history WHERE id = 1;'
"

# Удалить историю конкретного пользователя
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'DELETE FROM chat_history WHERE user_id = 123456789;'
"

# Удалить старые записи (старше 30 дней)
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c \"DELETE FROM chat_history WHERE created_at < NOW() - INTERVAL '30 days';\"
"

# Очистить всю таблицу
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'TRUNCATE TABLE chat_history;'
"
```

---

## 📈 Аналитика и статистика

### Топ активных пользователей

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
SELECT 
    user_id,
    COUNT(*) as total_messages,
    COUNT(CASE WHEN role = 'user' THEN 1 END) as user_messages,
    COUNT(CASE WHEN role = 'assistant' THEN 1 END) as bot_messages,
    MIN(created_at) as first_message,
    MAX(created_at) as last_message
FROM chat_history
GROUP BY user_id
ORDER BY total_messages DESC
LIMIT 10;
EOF
"
```

### Общая статистика

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
SELECT 
    COUNT(*) as total_messages,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN role = 'user' THEN 1 END) as user_messages,
    COUNT(CASE WHEN role = 'assistant' THEN 1 END) as bot_messages,
    MIN(created_at) as first_message,
    MAX(created_at) as last_message
FROM chat_history;
EOF
"
```

### Сообщения за последние 24 часа

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c \"SELECT COUNT(*) as messages_24h FROM chat_history WHERE created_at > NOW() - INTERVAL '24 hours';\"
"
```

---

## 💾 Бекап и восстановление

### Создать бекап таблицы

```bash
# Бекап в локальный файл
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres pg_dump -U n8n -d n8n -t chat_history
" > chat_history_backup_$(date +%Y%m%d_%H%M%S).sql

echo "Backup saved to: chat_history_backup_$(date +%Y%m%d_%H%M%S).sql"
```

### Бекап всей базы данных

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres pg_dump -U n8n -d n8n
" > n8n_full_backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановить из бекапа

```bash
# Восстановить таблицу
cat chat_history_backup_20260201_180000.sql | yc compute ssh --name n8n-server --command "
docker exec -i n8n-postgres psql -U n8n -d n8n
"
```

---

## 🔧 Обслуживание

### Очистка неиспользуемых данных

```bash
# Vacuum (очистка и оптимизация)
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'VACUUM ANALYZE chat_history;'
"
```

### Проверка размера таблицы

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
SELECT 
    pg_size_pretty(pg_total_relation_size('chat_history')) as total_size,
    pg_size_pretty(pg_relation_size('chat_history')) as table_size,
    pg_size_pretty(pg_indexes_size('chat_history')) as indexes_size;
EOF
"
```

### Размер всей базы данных

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n -c 'SELECT pg_size_pretty(pg_database_size(current_database()));'
"
```

---

## 🆘 Troubleshooting

### Ошибка: "relation does not exist"

Таблица не создана. Создай её:

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
EOF
"
```

### Ошибка: "FATAL: database does not exist"

Проверь имя базы данных:

```bash
yc compute ssh --name n8n-server --command "
docker exec n8n-postgres psql -U n8n -l
"
```

### Проверка логов PostgreSQL

```bash
yc compute ssh --name n8n-server --command "
docker logs n8n-postgres --tail=50
"
```

### Перезапуск PostgreSQL

```bash
yc compute ssh --name n8n-server --command "
cd /opt/n8n && docker compose restart postgres
"
```

### Подключение для отладки

Если нужна интерактивная работа, используй **Serial Console**:

1. Открой https://console.cloud.yandex.ru/
2. Compute Cloud → n8n-server → **Serial Console**
3. Залогинься как `ubuntu`
4. Выполни команды напрямую

---

## 📚 Полезные SQL команды

### Создание других таблиц

```sql
-- Пример: таблица для логов
CREATE TABLE IF NOT EXISTS bot_logs (
    id SERIAL PRIMARY KEY,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Индексы
CREATE INDEX idx_logs_level ON bot_logs(level);
CREATE INDEX idx_logs_created ON bot_logs(created_at DESC);
```

### Работа с JSONB

```sql
-- Вставка с JSON данными
INSERT INTO bot_logs (level, message, metadata) VALUES
  ('info', 'User started bot', '{"user_id": 123, "username": "john"}');

-- Запрос по JSON полю
SELECT * FROM bot_logs WHERE metadata->>'user_id' = '123';
```

---

## 🔗 Полезные ссылки

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [n8n PostgreSQL Node](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.postgres/)
- [Docker PostgreSQL](https://hub.docker.com/_/postgres)

---

**Создано:** 2026-02-01  
**Автор:** AI Agent  
**Статус:** ✅ Готово к использованию
