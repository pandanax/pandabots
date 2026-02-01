#!/bin/bash

# Скрипт для создания таблицы chat_history в PostgreSQL
# Использование: ./create-chat-history-table.sh

set -e

echo "🗄️  Создание таблицы chat_history в PostgreSQL..."
echo ""

# Проверка что мы на сервере или можем подключиться к Docker
if ! docker ps | grep -q n8n-postgres; then
    echo "❌ Ошибка: PostgreSQL контейнер не найден!"
    echo "   Убедитесь что вы на сервере или Docker Compose запущен"
    exit 1
fi

# Создание таблицы
echo "📝 Выполнение SQL команд..."
docker exec n8n-postgres psql -U n8n -d n8n << 'EOF'

-- Создать таблицу если не существует
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Создать индексы
CREATE INDEX IF NOT EXISTS idx_user_created ON chat_history(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_user_id ON chat_history(user_id);

-- Проверка
SELECT 
    'Таблица ' || table_name || ' имеет ' || count(*) || ' колонок' AS info
FROM information_schema.columns 
WHERE table_name = 'chat_history'
GROUP BY table_name;

SELECT 'Создано ' || count(*) || ' индексов' AS info
FROM pg_indexes
WHERE tablename = 'chat_history';

EOF

echo ""
echo "✅ Таблица chat_history успешно создана!"
echo ""
echo "📊 Проверка таблицы:"
docker exec n8n-postgres psql -U n8n -d n8n -c "\\dt chat_history"
echo ""
echo "📑 Индексы:"
docker exec n8n-postgres psql -U n8n -d n8n -c "\\di idx_user*"
echo ""
echo "✨ Готово! Теперь можно активировать Mandala Bot workflow в n8n"
