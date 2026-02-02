-- Создание таблицы для хранения профилей пользователей FitBot
-- Использование: через YC CLI команду

-- Создать таблицу если не существует
CREATE TABLE IF NOT EXISTS user_profiles (
    id SERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE NOT NULL,
    name VARCHAR(255),
    age INTEGER,
    weight DECIMAL(5,2),  -- в кг, например 75.50
    height INTEGER,       -- в см, например 175
    goal TEXT,            -- цель пользователя, например "хочу похудеть до 80 кг"
    onboarding_state VARCHAR(50) DEFAULT 'none',  -- состояние онбординга: none, awaiting_name, awaiting_age, awaiting_height, awaiting_weight, awaiting_goal, completed
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Валидация данных
    CONSTRAINT check_age CHECK (age >= 10 AND age <= 120),
    CONSTRAINT check_weight CHECK (weight >= 20 AND weight <= 500),
    CONSTRAINT check_height CHECK (height >= 100 AND height <= 300)
);

-- Создать индекс для быстрой выборки по user_id
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);

-- Создать индекс для состояния онбординга
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding_state ON user_profiles(onboarding_state);

-- Проверка что таблица создана
SELECT 
    table_name, 
    column_name, 
    data_type, 
    character_maximum_length,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;

-- Показать индексы
SELECT 
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'user_profiles';

-- Вывести успех
SELECT 'Таблица user_profiles успешно создана!' AS status;
