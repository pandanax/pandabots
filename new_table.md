[1 tool called]

## 📋 Таблица `user_profiles`

Мы добавили таблицу **`user_profiles`** для хранения профилей пользователей FitBot.

### 🔧 Поля:

| Поле | Тип | Описание |
|------|-----|----------|
| **`id`** | `SERIAL PRIMARY KEY` | Автоинкрементный ID записи |
| **`user_id`** | `BIGINT UNIQUE NOT NULL` | Telegram ID пользователя (уникальный) |
| **`name`** | `VARCHAR(255)` | Имя пользователя |
| **`age`** | `INTEGER` | Возраст (10-120 лет) |
| **`weight`** | `DECIMAL(5,2)` | Вес в кг (например 75.50) |
| **`height`** | `INTEGER` | Рост в см (например 175) |
| **`goal`** | `TEXT` | Цель пользователя (например "хочу похудеть до 80 кг") |
| **`onboarding_state`** | `VARCHAR(50)` | Состояние онбординга (по умолчанию `'none'`) |
| **`created_at`** | `TIMESTAMP` | Дата создания (NOW()) |
| **`updated_at`** | `TIMESTAMP` | Дата обновления (NOW()) |

### ✅ Валидация (CONSTRAINTS):

```sql
CONSTRAINT check_age CHECK (age >= 10 AND age <= 120)
CONSTRAINT check_weight CHECK (weight >= 20 AND weight <= 500)
CONSTRAINT check_height CHECK (height >= 100 AND height <= 300)
```

### 📊 Индексы:

1. **`idx_user_profiles_user_id`** - на поле `user_id` (быстрая выборка)
2. **`idx_user_profiles_onboarding_state`** - на поле `onboarding_state`

### 🔄 Состояния онбординга (`onboarding_state`):

- `none` - онбординг не начат или завершен
- `await_name` - ждет имя
- `await_age` - ждет возраст
- `await_height` - ждет рост
- `await_weight` - ждет вес
- `await_goal` - ждет цель

### 📂 Файлы:

- SQL скрипт: `scripts/create-user-profiles-table.sql`
- Bash скрипт: `scripts/create-user-profiles-table.sh`

### 🚀 Создать таблицу:

```bash
cd /Users/pandanax/dev/n8n/scripts
./create-user-profiles-table.sh
```