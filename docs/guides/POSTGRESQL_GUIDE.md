# 🗄️ Руководство по работе с PostgreSQL

> Как работать с **Yandex Managed PostgreSQL** через Yandex Cloud CLI

---

## ⚠️ ВАЖНО: Managed PostgreSQL, НЕ Docker!

**База данных работает как Yandex Managed PostgreSQL сервис**, а не в Docker контейнере.

### Подключение через SSH на VM

```bash
yc compute ssh --name n8n-server
```

Затем используй `psql` с параметрами:
```bash
PGPASSWORD='<пароль>' psql -h <host> -p 6432 -U n8n -d n8n
```

Пароль и хост берутся из `/Users/pandanax/dev/n8n/STATUS.md`

---

## 🔍 Проверка подключения

### Проверить подключение к Managed PostgreSQL

```bash
# Через SSH на VM
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n \
-c 'SELECT version();'
"
```

Ожидаемый результат:
```
PostgreSQL 15.x on x86_64-pc-linux-gnu
```

---

## 📋 Основные операции

### Список таблиц

```bash
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n \
-c '\dt'
"
```

### Структура конкретной таблицы

```bash
# Например, для таблицы chat_history
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n \
-c '\d chat_history'
"
```

### Список индексов

```bash
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n \
-c '\di'
"
```

---

## 🆕 Создание таблиц

### Используй скрипты из /Users/pandanax/dev/n8n/scripts/

Все таблицы создаются через скрипты:

```bash
cd /Users/pandanax/dev/n8n/scripts

# Создать таблицу chat_history
./create-chat-history-table.sh

# Создать таблицу user_profiles  
./create-user-profiles-table.sh

# Создать таблицу user_locks
./create-user-locks-table.sh
```

### Проверить что таблица создана

```bash
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n \
-c '\d chat_history'
"
```

---

## 📊 Работа с данными

### Базовая команда (алиас для удобства)

```bash
# Создай алиас для быстрого доступа
alias pgn8n="yc compute ssh --name n8n-server -- \"PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n\""
```

### Просмотр данных

```bash
# Количество записей
pgn8n -c 'SELECT COUNT(*) FROM chat_history;'

# Последние 10 сообщений
pgn8n -c 'SELECT id, user_id, role, LEFT(content, 50) as content_preview, created_at FROM chat_history ORDER BY created_at DESC LIMIT 10;'

# Сообщения конкретного пользователя
pgn8n -c 'SELECT * FROM chat_history WHERE user_id = 123456789 ORDER BY created_at DESC;'
```

### Вставка тестовых данных

```bash
pgn8n -c "INSERT INTO chat_history (user_id, role, content) VALUES (123456789, 'user', 'Привет!'), (123456789, 'assistant', 'Здравствуй! Как дела?');"
```

### Обновление данных

```bash
pgn8n -c "UPDATE chat_history SET content = 'Новый текст' WHERE id = 1;"
```

### Удаление данных

```bash
# Удалить конкретную запись
pgn8n -c 'DELETE FROM chat_history WHERE id = 1;'

# Удалить историю конкретного пользователя
pgn8n -c 'DELETE FROM chat_history WHERE user_id = 123456789;'

# Удалить старые записи (старше 30 дней)
pgn8n -c "DELETE FROM chat_history WHERE created_at < NOW() - INTERVAL '30 days';"

# Очистить всю таблицу
pgn8n -c 'TRUNCATE TABLE chat_history;'
```

---

## 📈 Аналитика и статистика

### Топ активных пользователей

```bash
pgn8n << 'EOF'
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
```

### Общая статистика

```bash
pgn8n << 'EOF'
SELECT 
    COUNT(*) as total_messages,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN role = 'user' THEN 1 END) as user_messages,
    COUNT(CASE WHEN role = 'assistant' THEN 1 END) as bot_messages,
    MIN(created_at) as first_message,
    MAX(created_at) as last_message
FROM chat_history;
EOF
```

### Сообщения за последние 24 часа

```bash
pgn8n -c "SELECT COUNT(*) as messages_24h FROM chat_history WHERE created_at > NOW() - INTERVAL '24 hours';"
```

---

## 💾 Бекап и восстановление

### Создать бекап таблицы

```bash
# Бекап в локальный файл
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
pg_dump -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n -t chat_history
" > chat_history_backup_$(date +%Y%m%d_%H%M%S).sql

echo "Backup saved to: chat_history_backup_$(date +%Y%m%d_%H%M%S).sql"
```

### Бекап всей базы данных

```bash
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
pg_dump -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n
" > n8n_full_backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановить из бекапа

```bash
# Восстановить таблицу
cat chat_history_backup_20260201_180000.sql | yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n
"
```

---

## 🔧 Обслуживание

### Очистка неиспользуемых данных

```bash
# Vacuum (очистка и оптимизация)
pgn8n -c 'VACUUM ANALYZE chat_history;'
```

### Проверка размера таблицы

```bash
pgn8n << 'EOF'
SELECT 
    pg_size_pretty(pg_total_relation_size('chat_history')) as total_size,
    pg_size_pretty(pg_relation_size('chat_history')) as table_size,
    pg_size_pretty(pg_indexes_size('chat_history')) as indexes_size;
EOF
```

### Размер всей базы данных

```bash
pgn8n -c 'SELECT pg_size_pretty(pg_database_size(current_database()));'
```

---

## 🆘 Troubleshooting

### Ошибка: "relation does not exist"

Таблица не создана. Используй скрипты:

```bash
cd /Users/pandanax/dev/n8n/scripts
./create-chat-history-table.sh
```

### Ошибка: "FATAL: database does not exist"

Проверь что БД существует:

```bash
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -l
"
```

### Проверка доступности Managed PostgreSQL

```bash
# Проверка через Yandex Cloud Console
# https://console.cloud.yandex.ru/folders/b1g8dn4l2a7t5r1g7i1k/managed-postgresql/cluster/
```

### Интерактивная работа

Подключись напрямую через SSH:

```bash
yc compute ssh --name n8n-server

# Затем на VM:
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n
```

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
- [Yandex Managed PostgreSQL](https://cloud.yandex.ru/docs/managed-postgresql/)
- [Yandex Cloud CLI](https://cloud.yandex.ru/docs/cli/)

---

**Создано:** 2026-02-01  
**Обновлено:** 2026-02-06 (убраны упоминания Docker, добавлена документация по Managed PostgreSQL)  
**Автор:** AI Agent  
**Статус:** ✅ Готово к использованию с Managed PostgreSQL
