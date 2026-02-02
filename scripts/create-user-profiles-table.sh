#!/bin/bash

# Скрипт для создания таблицы user_profiles в Managed PostgreSQL
# Использование: ./create-user-profiles-table.sh

set -e

echo "🗄️  Создание таблицы user_profiles в Managed PostgreSQL..."
echo ""

# Получаем пароль PostgreSQL из STATUS.md
echo "📝 Получение пароля PostgreSQL..."
PG_PASSWORD=$(grep "DB_POSTGRESDB_PASSWORD=" STATUS.md 2>/dev/null | head -1 | cut -d'=' -f2 || echo "")

if [ -z "$PG_PASSWORD" ]; then
    echo "❌ Ошибка: Не удалось найти пароль PostgreSQL в STATUS.md"
    echo "   Используйте: DB_POSTGRESDB_PASSWORD=<пароль> ./create-user-profiles-table.sh"
    if [ -n "$DB_POSTGRESDB_PASSWORD" ]; then
        PG_PASSWORD="$DB_POSTGRESDB_PASSWORD"
        echo "✅ Используем пароль из переменной окружения"
    else
        exit 1
    fi
fi

# Получаем хост PostgreSQL из YC CLI
echo "📝 Получение хоста PostgreSQL кластера..."
PG_HOST=$(yc managed-postgresql hosts list --cluster-name n8n-postgres --format json 2>/dev/null | grep -o '"fqdn": "[^"]*"' | head -1 | cut -d'"' -f4)

if [ -z "$PG_HOST" ]; then
    echo "❌ Ошибка: Не удалось получить хост PostgreSQL кластера"
    echo "   Проверьте что кластер 'n8n-postgres' существует"
    exit 1
fi

echo "✅ PostgreSQL Host: $PG_HOST"
echo "✅ PostgreSQL Port: 6432"
echo "✅ Database: n8n"
echo "✅ User: n8n"
echo ""

# Переключаемся на профиль pandanax для SSH
echo "🔄 Переключение на профиль pandanax для SSH..."
yc config profile activate pandanax > /dev/null 2>&1 || echo "⚠️  Профиль pandanax не найден, используем текущий"

# Выполнение SQL команд через SSH на ВМ n8n-server
echo "📝 Выполнение SQL команд через SSH на ВМ n8n-server..."
echo ""

yc compute ssh --name n8n-server -- "PGPASSWORD='$PG_PASSWORD' psql -h $PG_HOST -p 6432 -U n8n -d n8n << 'EOFINNER'
-- Создать таблицу если не существует
CREATE TABLE IF NOT EXISTS user_profiles (
    id SERIAL PRIMARY KEY,
    user_id BIGINT UNIQUE NOT NULL,
    name VARCHAR(255),
    age INTEGER,
    weight DECIMAL(5,2),
    height INTEGER,
    goal TEXT,
    onboarding_state VARCHAR(50) DEFAULT 'none',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    CONSTRAINT check_age CHECK (age >= 10 AND age <= 120),
    CONSTRAINT check_weight CHECK (weight >= 20 AND weight <= 500),
    CONSTRAINT check_height CHECK (height >= 100 AND height <= 300)
);

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_onboarding_state ON user_profiles(onboarding_state);

SELECT 'Таблица создана успешно!' AS status;
EOFINNER
"

echo ""
echo "✅ Таблица user_profiles успешно создана!"
echo ""

# Проверка структуры таблицы
echo "📊 Проверка структуры таблицы:"
yc compute ssh --name n8n-server -- "PGPASSWORD='$PG_PASSWORD' psql -h $PG_HOST -p 6432 -U n8n -d n8n -c '\d user_profiles'"

echo ""
echo "📑 Проверка индексов:"
yc compute ssh --name n8n-server -- "PGPASSWORD='$PG_PASSWORD' psql -h $PG_HOST -p 6432 -U n8n -d n8n -c '\di *user_profiles*'"

echo ""
echo "✨ Готово! Таблица user_profiles создана и готова к использованию в FitBot workflow"
