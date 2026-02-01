# 🛠️ Скрипты для автоматизации

Полезные скрипты для управления проектом n8n

---

## 📋 Список скриптов

### 1. `deploy.sh`
**Описание:** Развертывание n8n на сервере  
**Использование:** `./deploy.sh`

### 2. `setup-ssl.sh`
**Описание:** Настройка SSL сертификатов Let's Encrypt  
**Использование:** `./setup-ssl.sh`

### 3. `yc-wrapper.sh`
**Описание:** Wrapper для Yandex Cloud CLI  
**Использование:** `./yc-wrapper.sh <команда>`

### 4. `create-chat-history-table.sh` ⭐ NEW!
**Описание:** Создание таблицы chat_history в PostgreSQL для Mandala Bot  
**Использование:** 
```bash
# На сервере:
ssh ubuntu@<server-ip>
cd /opt/n8n
./create-chat-history-table.sh
```

**Что делает:**
- Создает таблицу `chat_history` с полями: id, user_id, role, content, created_at
- Создает индексы для оптимизации запросов
- Проверяет что таблица создана успешно

---

## 🗄️ Создание таблицы chat_history

Для работы **Mandala Bot Advanced** нужна таблица в PostgreSQL.

### Вариант 1: Автоматический (рекомендуется)

```bash
# На сервере
ssh ubuntu@<server-ip>
cd /opt/n8n
./create-chat-history-table.sh
```

### Вариант 2: Вручную через SQL

```bash
# На сервере
ssh ubuntu@<server-ip>

# Подключиться к PostgreSQL
docker exec -it n8n-postgres psql -U n8n -d n8n

# Создать таблицу
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_user_created ON chat_history(user_id, created_at DESC);
CREATE INDEX idx_user_id ON chat_history(user_id);

-- Проверка
\dt chat_history
\di idx_user*
```

### Вариант 3: Из SQL файла

```bash
# На сервере
ssh ubuntu@<server-ip>
cd /opt/n8n/scripts

# Выполнить SQL скрипт
docker exec -i n8n-postgres psql -U n8n -d n8n < create-chat-history-table.sql
```

---

## 🔍 Проверка таблицы

```bash
# Показать структуру таблицы
docker exec n8n-postgres psql -U n8n -d n8n -c "\\d chat_history"

# Показать индексы
docker exec n8n-postgres psql -U n8n -d n8n -c "\\di idx_user*"

# Проверить количество записей
docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT COUNT(*) FROM chat_history;"

# Показать последние 10 сообщений
docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT * FROM chat_history ORDER BY created_at DESC LIMIT 10;"
```

---

## 🗑️ Очистка данных

### Удалить историю конкретного пользователя

```bash
docker exec n8n-postgres psql -U n8n -d n8n -c "DELETE FROM chat_history WHERE user_id = <USER_ID>;"
```

### Удалить старые сообщения (старше 30 дней)

```bash
docker exec n8n-postgres psql -U n8n -d n8n -c "DELETE FROM chat_history WHERE created_at < NOW() - INTERVAL '30 days';"
```

### Очистить всю таблицу

```bash
docker exec n8n-postgres psql -U n8n -d n8n -c "TRUNCATE TABLE chat_history;"
```

---

## 📊 Аналитика

### Статистика по пользователям

```bash
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
-- Топ 10 активных пользователей
SELECT 
    user_id, 
    COUNT(*) as messages,
    MIN(created_at) as first_message,
    MAX(created_at) as last_message
FROM chat_history 
GROUP BY user_id 
ORDER BY messages DESC 
LIMIT 10;
EOF
```

### Общая статистика

```bash
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'
SELECT 
    COUNT(*) as total_messages,
    COUNT(DISTINCT user_id) as unique_users,
    COUNT(CASE WHEN role = 'user' THEN 1 END) as user_messages,
    COUNT(CASE WHEN role = 'assistant' THEN 1 END) as bot_messages
FROM chat_history;
EOF
```

---

## 🔄 Бекап и восстановление

### Создать бекап таблицы

```bash
docker exec n8n-postgres pg_dump -U n8n -t chat_history n8n > chat_history_backup_$(date +%Y%m%d).sql
```

### Восстановить из бекапа

```bash
cat chat_history_backup_YYYYMMDD.sql | docker exec -i n8n-postgres psql -U n8n -d n8n
```

---

## 🆘 Troubleshooting

### Ошибка: "relation chat_history does not exist"

```bash
# Проверить существует ли таблица
docker exec n8n-postgres psql -U n8n -d n8n -c "\\dt"

# Если нет - создать
./create-chat-history-table.sh
```

### Ошибка: "permission denied"

```bash
# Дать права на выполнение
chmod +x create-chat-history-table.sh
```

### Проверка подключения к PostgreSQL

```bash
# Проверить что контейнер запущен
docker ps | grep postgres

# Проверить логи
docker logs n8n-postgres

# Тестовое подключение
docker exec n8n-postgres psql -U n8n -d n8n -c "SELECT version();"
```

---

**Создано:** 2026-02-01  
**Обновлено:** 2026-02-01
