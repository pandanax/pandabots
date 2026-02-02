# Настройка FitBot - Помощника по пищевому поведению

## Обзор

FitBot - это Telegram бот-консультант по здоровому питанию и коррекции пищевого поведения. Использует DeepSeek AI с научной базой знаний (RAG) о физиологии похудения и сохраняет историю диалогов в PostgreSQL.

**Основные возможности:**
- Консультации по правильному питанию
- Разработка индивидуальных планов питания
- Коррекция пищевого поведения
- Научно обоснованные рекомендации по снижению веса
- Развенчание мифов о диетах
- Память о предыдущих диалогах с каждым пользователем

## Архитектура

```
Telegram → n8n Workflow → DeepSeek AI (с RAG) → PostgreSQL (история) → Telegram
```

**Компоненты:**
1. **Telegram Bot** - интерфейс взаимодействия с пользователем
2. **n8n Workflow** - оркестрация процесса
3. **DeepSeek V3** - AI модель для генерации ответов
4. **PostgreSQL** - хранение истории диалогов
5. **RAG система** - научная база знаний о питании и похудении

## Предварительные требования

### 1. Telegram Bot Token

Создайте нового бота через [@BotFather](https://t.me/botfather):

```
/newbot
```

Следуйте инструкциям:
- Имя бота: `FitBot Nutrition Assistant`
- Username: `your_fitbot` (должен заканчиваться на `bot`)

Сохраните полученный **Bot Token** (формат: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`).

**Рекомендуемые настройки бота:**

```bash
# Описание бота
/setdescription
# Ваш личный консультант по здоровому питанию и коррекции пищевого поведения. 
# Научно обоснованные рекомендации, индивидуальный подход, поддержка на всех этапах.

# Короткое описание
/setabouttext
# Профессиональный консультант по питанию на базе AI

# Команды
/setcommands
start - Начать диалог с FitBot
help - Показать справку
reset - Сбросить историю диалога
info - Информация о научном подходе

# Изображение профиля (опционально)
/setuserpic
```

### 2. DeepSeek API Key

Получите API ключ:
1. Зарегистрируйтесь на [DeepSeek Platform](https://platform.deepseek.com)
2. Пополните баланс (минимум $5)
3. Создайте API Key в разделе API Keys
4. Сохраните ключ (формат: `sk-...`)

**Стоимость использования DeepSeek V3:**
- Input: $0.27 / 1M tokens
- Output: $1.10 / 1M tokens
- Cache hits: $0.014 / 1M tokens

### 3. База данных PostgreSQL

База данных уже настроена через Yandex Managed PostgreSQL. Убедитесь что таблица `chat_history` создана:

```sql
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
);
```

### 4. База знаний (RAG)

База знаний должна быть размещена на сервере в `/home/node/.n8n-files/rags/fitbot/knowledge.txt`.

Файл уже подготовлен в репозитории: `rags/fitbot/knowledge.txt`

**Содержание базы знаний:**
- Фундаментальные принципы физиологии похудения
- Биохимия энергетического обмена
- Научные основы правильного питания
- Практические протоколы питания
- Развенчание популярных мифов
- Роль макронутриентов (БЖУ)

## Установка и настройка

### Шаг 1: Загрузка базы знаний на сервер

Скопируйте всю папку `rags` на сервер:

```bash
# Из корня репозитория
scp -r rags/ user@your-server:/home/node/.n8n-files/

# Проверьте права доступа
ssh user@your-server
ls -la /home/node/.n8n-files/rags/fitbot/
# Должен быть виден файл knowledge.txt
```

**Альтернатива через rsync:**

```bash
rsync -avz --progress rags/ user@your-server:/home/node/.n8n-files/rags/
```

### Шаг 2: Импорт workflow в n8n

1. Откройте n8n веб-интерфейс: `https://n8n.your-domain.com`
2. Нажмите **+** (Create new workflow)
3. Нажмите **⋮** (три точки) → **Import from File**
4. Загрузите файл `workflows/telegram-fitbot.json`
5. Workflow будет импортирован

### Шаг 3: Настройка Credentials

#### 3.1 Telegram API Credentials

1. Откройте импортированный workflow
2. Кликните на узел **Telegram Trigger**
3. В поле **Credentials** кликните на **FITBOT_CREDENTIALS_ID**
4. Выберите **Create New Credential**
5. Заполните:
   - **Credential Name**: `FitBot Telegram`
   - **Access Token**: вставьте Bot Token от BotFather
6. Нажмите **Save**
7. Повторите для узла **Send AI Reply** (выберите тот же credential)

#### 3.2 DeepSeek API Credentials

1. Кликните на узел **DeepSeek AI**
2. Credential уже может быть настроен (`DeepSeekV3`)
3. Если нет - создайте новый:
   - **Credential Type**: `OpenAI API`
   - **Credential Name**: `DeepSeekV3`
   - **API Key**: ваш DeepSeek API ключ
   - **Base URL**: `https://api.deepseek.com/v1`
4. Нажмите **Save**

#### 3.3 PostgreSQL Credentials

Credentials уже настроены (`Postgres account`), но проверьте подключение:

1. Кликните на узел **Load Chat History**
2. Проверьте credential `Postgres account`
3. Убедитесь что параметры совпадают с `.env`:
   - Host: из `DB_POSTGRESDB_HOST`
   - Port: `6432`
   - Database: `n8n`
   - User: `n8n`
   - Password: из `DB_POSTGRESDB_PASSWORD`
   - SSL: `Enabled`

### Шаг 4: Активация workflow

1. Сохраните workflow: **Ctrl+S** или кнопка **Save**
2. Активируйте: переключите тумблер **Active** в правом верхнем углу
3. Проверьте что статус **Active**

## Тестирование

### 1. Базовое тестирование

Откройте Telegram и найдите вашего бота по username (например, `@your_fitbot`):

```
/start
```

Попробуйте простой диалог:

```
Привет! Хочу похудеть, с чего начать?
```

Бот должен ответить развёрнутым сообщением с рекомендациями.

### 2. Тестирование RAG (базы знаний)

Задайте специфический вопрос из базы знаний:

```
Что такое адаптивный термогенез?
```

Бот должен дать ответ, основанный на научных данных из `knowledge.txt`.

### 3. Тестирование истории диалога

```
Пользователь: Мой вес 85 кг, рост 175 см
Бот: [ответ с рекомендациями]

Пользователь: А сколько калорий мне нужно?
Бот: [должен помнить ваши параметры из предыдущего сообщения]
```

### 4. Проверка логов в n8n

1. Откройте workflow в n8n
2. Перейдите на вкладку **Executions**
3. Найдите последнее выполнение
4. Проверьте что все узлы отработали успешно (зелёные галочки)

## Структура Workflow

### Узлы и их функции

1. **Telegram Trigger** - получает сообщения от пользователей
2. **Extract User Data** - извлекает userId, chatId, userName, timestamp
3. **Load Chat History** - загружает последние 10 сообщений из PostgreSQL
4. **Format History** - форматирует историю для AI
5. **Read Knowledge Base** - читает файл базы знаний
6. **Load RAG Knowledge** - парсит содержимое базы знаний
7. **Merge Branches** - объединяет историю и базу знаний
8. **Build AI Context** - формирует промпт для DeepSeek AI
9. **DeepSeek AI** - генерирует ответ через API
10. **Format Response** - форматирует ответ для отправки
11. **Prepare for Save** - подготавливает данные для сохранения в БД
12. **Save to History** - сохраняет диалог в PostgreSQL
13. **Send AI Reply** - отправляет ответ пользователю в Telegram

### Параллельные ветки

Workflow использует две параллельные ветки после триггера:
- **Ветка 1**: Загрузка истории из БД
- **Ветка 2**: Чтение базы знаний

Они объединяются в узле **Merge Branches** для передачи AI.

## Настройка System Prompt

System prompt определяет поведение бота. Находится в узле **Build AI Context**.

**Текущий промпт:**

```javascript
Ты профессиональный консультант по здоровому питанию и коррекции пищевого поведения.

Твоя задача - помогать клиентам:
1. Понять основы правильного питания и физиологии похудения
2. Разработать индивидуальный план питания
3. Скорректировать пищевое поведение
4. Достичь целей по снижению веса безопасно и эффективно
5. Развенчать мифы о диетах и похудении

[...база знаний вставляется сюда...]
```

**Кастомизация:**

Вы можете изменить промпт в узле **Build AI Context**, секция `jsCode`:

```javascript
const messages = [
  {
    role: 'system',
    content: `[ваш кастомный промпт]`
  }
];
```

**Параметры настройки:**
- `max_tokens: 1000` - максимальная длина ответа (ограничено для Telegram)
- `temperature: 0.7` - креативность (0.0-1.0, меньше = более фактологично)

**Важно:** Telegram имеет лимит 4096 символов на сообщение. Поэтому:
- `max_tokens` установлен в 1000 (≈ 3500-4000 символов)
- В system prompt явно указано требование краткости
- AI будет генерировать лаконичные ответы

## Обновление базы знаний

### Локальное обновление

1. Отредактируйте файл `rags/fitbot/knowledge.txt`
2. Загрузите обновлённый файл на сервер:

```bash
scp rags/fitbot/knowledge.txt user@your-server:/home/node/.n8n-files/rags/fitbot/
```

3. Перезапустите workflow (деактивируйте и активируйте снова) или подождите следующего запуска

### Добавление новых разделов

База знаний структурирована по разделам:
- I. ФУНДАМЕНТАЛЬНЫЕ ПРИНЦИПЫ
- II. БИОХИМИЯ ЭНЕРГЕТИЧЕСКОГО ОБМЕНА
- III. ЭНЕРГЕТИЧЕСКИЙ БАЛАНС
- IV. РЕЖИМ ПИТАНИЯ
- V. МАКРОНУТРИЕНТЫ
- VI. ПРАКТИЧЕСКИЙ ПРОТОКОЛ ПИТАНИЯ
- VII. РАЗВЕНЧАНИЕ МИФОВ
- VIII. КЛЮЧЕВЫЕ ВЫВОДЫ
- IX. ФИЗИОЛОГИЧЕСКОЕ ОБОСНОВАНИЕ УСПЕХА

Вы можете добавлять новые разделы, сохраняя структуру:

```markdown
## X. НОВЫЙ РАЗДЕЛ

### X.1 Подраздел

**Ключевой факт:** описание

**Практический вывод:** рекомендации
```

## Мониторинг и оптимизация

### Проверка использования API

DeepSeek Dashboard: https://platform.deepseek.com/usage

- Отслеживайте потребление токенов
- Пополняйте баланс при необходимости
- Анализируйте самые длинные запросы

### Оптимизация запросов

**Сокращение токенов:**
1. Уменьшите `max_tokens` в узле **DeepSeek AI**
2. Сократите base knowledge (оставьте только ключевую информацию)
3. Уменьшите количество загружаемых сообщений истории (с 10 до 5)

В узле **Load Chat History**:
```sql
-- Было:
SELECT role, content, created_at FROM chat_history 
WHERE user_id = {{ $json.userId }} 
ORDER BY created_at DESC LIMIT 10

-- Стало:
SELECT role, content, created_at FROM chat_history 
WHERE user_id = {{ $json.userId }} 
ORDER BY created_at DESC LIMIT 5
```

### Очистка старой истории

Настройте автоматическую очистку через SQL:

```sql
-- Удаляем сообщения старше 30 дней
DELETE FROM chat_history 
WHERE created_at < NOW() - INTERVAL '30 days';
```

Добавьте это как scheduled workflow в n8n.

## Устранение неполадок

### Бот не отвечает

**Проверка 1: Webhook активен**
1. Откройте workflow
2. Убедитесь что **Active** включён
3. Проверьте **Executions** - есть ли новые выполнения?

**Проверка 2: Telegram Trigger**
1. Кликните на узел **Telegram Trigger**
2. В поле **Webhook URL** должна быть ссылка вида: `https://n8n.your-domain.com/webhook/fitbot-telegram-trigger`
3. Проверьте доступность URL в браузере

**Проверка 3: Credentials**
- Проверьте Telegram Bot Token
- Убедитесь что бот не заблокирован (@BotFather → /mybots → выберите бота)

### Ошибка "База знаний не загружена"

**Проблема:** Файл `knowledge.txt` не найден или недоступен.

**Решение:**
1. Проверьте путь на сервере:
```bash
ssh user@your-server
ls -la /home/node/.n8n-files/rags/fitbot/knowledge.txt
```

2. Проверьте права доступа:
```bash
chmod 644 /home/node/.n8n-files/rags/fitbot/knowledge.txt
```

3. Проверьте что volume смонтирован в Docker:
```bash
docker exec -it n8n ls -la /home/node/.n8n-files/rags/fitbot/
```

### Ошибка подключения к PostgreSQL

**Проблема:** Cannot connect to database

**Решение:**
1. Проверьте credentials в n8n
2. Проверьте `.env` файл на сервере
3. Убедитесь что PostgreSQL кластер запущен (Yandex Cloud Console)
4. Проверьте сетевую доступность:
```bash
telnet <DB_HOST> 6432
```

### DeepSeek API ошибки

**Ошибка 401 Unauthorized:**
- Проверьте API ключ
- Убедитесь что ключ активен (DeepSeek Dashboard)

**Ошибка 429 Too Many Requests:**
- Достигнут rate limit
- Подождите 1 минуту и повторите

**Ошибка 402 Payment Required:**
- Недостаточно средств на балансе DeepSeek
- Пополните баланс: https://platform.deepseek.com/billing

## Расширенные возможности

### Добавление команд бота

В узле **Extract User Data** добавьте обработку команд:

```javascript
const text = $json.message.text;

if (text.startsWith('/start')) {
  // Приветственное сообщение
  return [{
    json: {
      response: 'Привет! Я FitBot, ваш консультант по питанию...'
    }
  }];
}

if (text.startsWith('/reset')) {
  // Очистить историю пользователя
  // Реализация через отдельный SQL запрос
}
```

### Добавление файлового ввода

Можно расширить бота для приёма фото еды и анализа калорийности:

1. В **Telegram Trigger** добавьте `photo` в **Updates**
2. Добавьте узел для обработки изображений
3. Используйте Vision API (GPT-4V, Claude Vision) для анализа

### Интеграция с календарём питания

Добавьте узлы для:
- Создания записей в Google Calendar
- Отправки напоминаний о приёмах пищи
- Отслеживания прогресса

## Best Practices

### Безопасность

1. **Никогда** не храните токены в workflow
2. Используйте **Credentials** для всех API ключей
3. Включите SSL для PostgreSQL
4. Регулярно ротируйте API ключи

### Производительность

1. Ограничьте `max_tokens` разумным значением (1500-2000)
2. Используйте кэширование истории (не загружайте всю историю каждый раз)
3. Оптимизируйте базу знаний (удалите дублирующуюся информацию)

### UX

1. Используйте **Markdown** для форматирования ответов
2. Добавьте эмодзи для улучшения читаемости
3. Структурируйте длинные ответы списками и заголовками
4. Отвечайте быстро (оптимизируйте промпт)

### Мониторинг

1. Регулярно проверяйте **Executions** в n8n
2. Настройте алерты на ошибки (через n8n Error Trigger)
3. Отслеживайте баланс DeepSeek API
4. Мониторьте размер БД PostgreSQL

## Поддержка

### Логи и отладка

**n8n logs:**
```bash
docker logs n8n
```

**PostgreSQL logs:**
Через Yandex Cloud Console → Managed Service for PostgreSQL → Logs

**Telegram Bot logs:**
Используйте **Executions** в n8n для просмотра данных каждого запроса.

### Обновление workflow

1. Экспортируйте текущий workflow (на всякий случай)
2. Внесите изменения
3. Сохраните workflow
4. Протестируйте на тестовом аккаунте
5. Активируйте для production

## Дополнительные ресурсы

- [n8n Documentation](https://docs.n8n.io/)
- [DeepSeek API Docs](https://platform.deepseek.com/api-docs)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

## Лицензия и ответственность

**Медицинский дисклеймер:**

FitBot предоставляет общую информацию о питании и не заменяет консультацию с квалифицированным диетологом или врачом. Перед началом любой диеты или программы похудения проконсультируйтесь со специалистом.

---

**Версия документа:** 1.0  
**Дата создания:** 2026-02-02  
**Автор:** pandanax
