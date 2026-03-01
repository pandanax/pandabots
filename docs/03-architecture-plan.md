# Архитектура проекта n8n AI Bots

## Обзор

Проект представляет собой платформу для создания AI ботов в Telegram на базе n8n.
Каждый бот умеет работать с контекстом пользователей, сохраняя историю переписки и информацию по user_id.

## Цели проекта

- Развернуть n8n с веб-интерфейсом
- Доступ через домен с HTTPS
- Создание множества Telegram ботов
- Хранение контекста пользователей в БД
- Возможность работы как в групповых, так и в индивидуальных чатах

## Ограничения

- **Бюджет:** 10-15 тыс руб/мес максимум
- **Масштаб:** Песочница на 1 ВМ (не прод)
- **Пользователи:** Сначала для себя, потом друзья

## Технический стек

### Инфраструктура
- **Облако:** Yandex Cloud
- **Регион:** ru-central1-b
- **ВМ:** 1 инстанс (sandbox)

### Приложения
- **n8n:** Orchestration платформа (Docker)
- **PostgreSQL:** Основная БД (Yandex Managed PostgreSQL)
- **Nginx:** Reverse proxy + SSL (Docker)
- **Certbot:** Автоматическое получение SSL сертификатов

### Домен и DNS
- **Домен:** mandala-app.online (reg.ru)
- **DNS:** A-запись на external IP ВМ
- **SSL:** Let's Encrypt (автоматическое обновление)

## Архитектура на одной ВМ

```
                    Internet
                       |
                       v
                [mandala-app.online]
                       |
                       v
              [External IP: XXX.XXX.XXX.XXX]
                       |
                       v
            +----------+----------+
            |   Yandex Cloud VM   |
            |   ru-central1-b     |
            +---------------------+
            |                     |
            |  Docker Compose:    |
            |                     |
            |  +---------------+  |
            |  | Nginx :80/443 |  |
            |  | - SSL (LE)    |  |
            |  | - Proxy       |  |
            |  +-------+-------+  |
            |          |          |
            |          v          |
            |  +---------------+  |
            |  |   n8n :5678   |  |
            |  | - Workflows   |  |
            |  | - Bots        |  |
            |  +-------+-------+  |
            |          |          |
            |          v          |
            |  +---------------+  |
            |  | PostgreSQL    |  |
            |  | :5432         |  |
            |  | - n8n data    |  |
            |  | - bot context |  |
            |  | - user data   |  |
            |  +---------------+  |
            |                     |
            |  Volumes:           |
            |  - n8n_data         |
            |  - postgres_data    |
            +---------------------+
                       |
                       v
                [Telegram API]
```

## Спецификация ВМ

### Рекомендуемая конфигурация
```yaml
Platform: standard-v3
vCPU: 2 cores
RAM: 4 GB
Disk: 30 GB (SSD)
External IP: Статический
Zone: ru-central1-b
OS: Ubuntu 22.04 LTS
```

### Примерная стоимость (~8-10 тыс руб/мес)
- vCPU (2 cores): ~3000 руб/мес
- RAM (4 GB): ~1600 руб/мес
- Disk (30 GB SSD): ~450 руб/мес
- External IP: ~200 руб/мес
- Трафик: ~500-1000 руб/мес
- **Итого:** ~5750-6250 руб/мес + трафик

💡 **Запас в бюджете остается для возможного масштабирования**

### Минимальная конфигурация (если нужно экономить)
```yaml
Platform: standard-v2
vCPU: 2 cores
RAM: 2 GB
Disk: 20 GB (HDD)
External IP: Статический
```
**Стоимость:** ~3-4 тыс руб/мес

## Структура данных в PostgreSQL

### База данных n8n
- Workflows (воркфлоу n8n)
- Executions (история выполнений)
- Credentials (учетные данные)

### База данных для ботов (создадим отдельно)
```sql
-- Таблица пользователей
users (
  id SERIAL PRIMARY KEY,
  telegram_id BIGINT UNIQUE NOT NULL,
  username VARCHAR(255),
  first_name VARCHAR(255),
  created_at TIMESTAMP DEFAULT NOW()
)

-- Таблица сообщений (контекст)
messages (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  bot_id VARCHAR(100),
  message_text TEXT,
  message_type VARCHAR(50), -- user, bot, system
  created_at TIMESTAMP DEFAULT NOW()
)

-- Таблица метаданных пользователей
user_metadata (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  key VARCHAR(255),
  value TEXT,
  updated_at TIMESTAMP DEFAULT NOW()
)
```

## Docker Compose структура

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      - POSTGRES_USER=n8n
      - POSTGRES_PASSWORD=<secure-password>
      - POSTGRES_DB=n8n
    volumes:
      - postgres_data:/var/lib/postgresql/data
    
  n8n:
    image: n8nio/n8n:latest
    environment:
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=n8n
      - DB_POSTGRESDB_PASSWORD=<secure-password>
      - N8N_HOST=mandala-app.online
      - N8N_PROTOCOL=https
      - WEBHOOK_URL=https://mandala-app.online/
    volumes:
      - n8n_data:/home/node/.n8n
    depends_on:
      - postgres
    
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    depends_on:
      - n8n

  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot

volumes:
  postgres_data:
  n8n_data:
```

## Безопасность

### Firewall (Yandex Cloud Security Groups)
```yaml
Правила входящего трафика:
  - Port 22 (SSH): только с твоего IP
  - Port 80 (HTTP): любой (для Let's Encrypt)
  - Port 443 (HTTPS): любой
  
Правила исходящего трафика:
  - Все порты: разрешено (для доступа к Telegram API)
```

### Дополнительные меры
- SSH ключи (без паролей)
- Fail2ban для защиты от брутфорса
- Регулярные бэкапы PostgreSQL
- Секреты в .env файле (не в git)

## DNS настройка (reg.ru)

```
Тип    Хост                Значение              TTL
A      @                   <VM_EXTERNAL_IP>      300
A      www                 <VM_EXTERNAL_IP>      300
CNAME  n8n                 mandala-app.online.   300
```

После настройки n8n будет доступен:
- https://mandala-app.online
- https://www.mandala-app.online
- https://n8n.mandala-app.online (опционально)

## Выбранная конфигурация

✅ **ВМ:** 2 vCPU / 4 GB RAM (рекомендуемая)
✅ **Домен:** n8n.mandala-app.online
✅ **IaC:** Terraform для управления инфраструктурой

## План развертывания (пошагово)

### Фаза 0: Подготовка Terraform
1. ✅ Создать Service Account
2. ✅ Настроить доступ к облаку
3. 🔲 Установить Terraform
4. 🔲 Создать структуру проекта Terraform
5. 🔲 Настроить Terraform provider для Yandex Cloud
6. 🔲 Создать переменные и outputs

### Фаза 1: Инфраструктура через Terraform
1. ✅ Создать VPC и подсеть
2. ✅ Создать Security Group
3. ✅ Зарезервировать статический external IP (84.252.137.46)
4. ✅ Создать виртуальную машину (epdk7h2graaa04985hl0)
5. ✅ Применить Terraform конфигурацию
6. 🔲 Настроить DNS записи в reg.ru

### Фаза 2: Подготовка сервера
1. 🔲 Подключиться к ВМ по SSH
2. 🔲 Обновить систему
3. 🔲 Установить Docker и Docker Compose
4. 🔲 Настроить firewall (ufw)
5. 🔲 Настроить fail2ban

### Фаза 3: Развертывание приложения
1. 🔲 Создать docker-compose.yml
2. 🔲 Создать nginx конфигурацию
3. 🔲 Запустить PostgreSQL
4. 🔲 Получить SSL сертификат (Let's Encrypt)
5. 🔲 Запустить n8n
6. 🔲 Настроить Nginx с SSL

### Фаза 4: Настройка n8n
1. 🔲 Первый вход в n8n
2. 🔲 Создать административную учетную запись
3. 🔲 Настроить Telegram credentials
4. 🔲 Создать тестовый workflow
5. 🔲 Создать первого бота

### Фаза 5: База данных для ботов
1. 🔲 Создать отдельную БД для контекста
2. 🔲 Создать таблицы (users, messages, metadata)
3. 🔲 Настроить n8n workflows для работы с БД
4. 🔲 Протестировать сохранение контекста

### Фаза 6: Тестирование и оптимизация
1. 🔲 Проверить работу ботов
2. 🔲 Настроить мониторинг
3. 🔲 Настроить бэкапы
4. 🔲 Документировать процессы

## Риски и ограничения

### Технические риски
- **Один сервер = single point of failure**
  - Решение: Регулярные бэкапы, быстрое восстановление
- **Ограничения по памяти при большой нагрузке**
  - Решение: Мониторинг, возможность увеличить ресурсы ВМ
- **SSL сертификат может не обновиться автоматически**
  - Решение: Настроить cron для автообновления

### Бюджетные риски
- **Превышение трафика**
  - Решение: Мониторинг расходов, лимиты в Yandex Cloud
- **Необходимость масштабирования**
  - Решение: Запас в бюджете 10-15к

## Следующий шаг

После согласования плана начнем с **Фазы 1: Инфраструктура**
Первый конкретный шаг: создание VPC и подсети.

## Вопросы для уточнения

Перед началом реализации:

1. Устраивает ли спецификация ВМ (2 vCPU / 4GB RAM)?
2. Хочешь начать с минимальной конфигурации для экономии?
3. Нужен ли отдельный поддомен для n8n (n8n.mandala-app.online)?
4. Согласен с планом развертывания по фазам?
