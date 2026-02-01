-- Создание таблицы для хранения истории чата
-- Использование: docker exec -i n8n-postgres psql -U n8n -d n8n < create-chat-history-table.sql

-- Создать таблицу если не существует
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Создать индекс для быстрой выборки по пользователю и дате
CREATE INDEX IF NOT EXISTS idx_user_created ON chat_history(user_id, created_at DESC);

-- Создать индекс для быстрого подсчета сообщений пользователя
CREATE INDEX IF NOT EXISTS idx_user_id ON chat_history(user_id);

-- Проверка что таблица создана
SELECT 
    table_name, 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'chat_history'
ORDER BY ordinal_position;

-- Показать индексы
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'chat_history';

-- Вывести успех
SELECT 'Таблица chat_history успешно создана!' AS status;
