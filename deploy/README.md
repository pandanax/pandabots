# n8n Deployment

Конфигурация для развертывания n8n с PostgreSQL, Nginx и Let's Encrypt SSL.

## Быстрый старт

### 1. Подготовка конфигурации

```bash
# Скопируйте .env.example в .env
cp .env.example .env

# Отредактируйте .env и установите:
# - Сильный пароль для PostgreSQL
# - Encryption key (openssl rand -hex 32)
# - Ваш email для Let's Encrypt
nano .env
```

### 2. Генерация encryption key

```bash
openssl rand -hex 32
```

Скопируйте результат в `.env` как значение `N8N_ENCRYPTION_KEY`.

### 3. Первый запуск (без SSL)

При первом запуске нужно временно изменить nginx конфигурацию для получения сертификата:

```bash
# Запустите только базу данных и n8n
docker compose up -d postgres n8n

# Подождите ~30 секунд пока БД инициализируется
docker compose logs -f n8n
```

### 4. Получение SSL сертификата

```bash
# Запустите nginx
docker compose up -d nginx

# Получите сертификат Let's Encrypt
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d n8n.mandala-app.online

# Перезапустите nginx для применения сертификата
docker compose restart nginx
```

### 5. Запуск всех сервисов

```bash
docker compose up -d
```

### 6. Проверка статуса

```bash
# Проверка всех контейнеров
docker compose ps

# Логи n8n
docker compose logs -f n8n

# Логи nginx
docker compose logs -f nginx
```

## Структура проекта

```
deploy/
├── docker-compose.yml      # Основная конфигурация Docker Compose
├── .env                    # Переменные окружения (не в git!)
├── .env.example            # Пример конфигурации
├── nginx/
│   ├── nginx.conf          # Основная конфигурация Nginx
│   └── conf.d/
│       └── default.conf    # Конфигурация виртуального хоста
└── README.md               # Эта инструкция
```

## Управление

### Остановка сервисов

```bash
docker compose down
```

### Обновление n8n

```bash
docker compose pull n8n
docker compose up -d n8n
```

### Просмотр логов

```bash
# Все сервисы
docker compose logs -f

# Конкретный сервис
docker compose logs -f n8n
docker compose logs -f postgres
docker compose logs -f nginx
```

### Резервное копирование

```bash
# Backup PostgreSQL
docker compose exec postgres pg_dump -U n8n n8n > backup-$(date +%Y%m%d).sql

# Backup n8n данных
docker compose exec n8n tar czf /tmp/n8n-data.tar.gz /home/node/.n8n
docker compose cp n8n:/tmp/n8n-data.tar.gz ./n8n-data-$(date +%Y%m%d).tar.gz
```

### Восстановление

```bash
# Restore PostgreSQL
cat backup.sql | docker compose exec -T postgres psql -U n8n n8n

# Restore n8n данных
docker compose cp n8n-data.tar.gz n8n:/tmp/
docker compose exec n8n tar xzf /tmp/n8n-data.tar.gz -C /
docker compose restart n8n
```

## Безопасность

1. **Пароли**: Используйте сильные случайные пароли (минимум 32 символа)
2. **Encryption Key**: Сгенерируйте через `openssl rand -hex 32`
3. **Firewall**: UFW уже настроен на сервере
4. **SSL**: Автоматическое обновление через certbot каждые 12 часов
5. **Backup**: Регулярно делайте резервные копии БД и данных n8n

## Мониторинг

### Здоровье контейнеров

```bash
docker compose ps
```

### Использование ресурсов

```bash
docker stats
```

### Disk usage

```bash
docker system df
```

## Troubleshooting

### n8n не запускается

```bash
# Проверьте логи
docker compose logs n8n

# Убедитесь что PostgreSQL готов
docker compose exec postgres pg_isready -U n8n
```

### SSL не работает

```bash
# Проверьте сертификаты
docker compose exec nginx ls -la /etc/letsencrypt/live/n8n.mandala-app.online/

# Проверьте nginx конфигурацию
docker compose exec nginx nginx -t

# Пересоздайте сертификат
docker compose run --rm certbot certonly --force-renewal \
  --webroot --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  -d n8n.mandala-app.online
```

### Очистка старых данных

```bash
# Удалить неиспользуемые images
docker image prune -a

# Удалить все (ВНИМАНИЕ: потеряете данные!)
docker compose down -v
```

## Доступ к n8n

После успешного запуска:

- URL: https://n8n.mandala-app.online
- При первом входе создайте admin аккаунт
- Настройте workflow и начинайте автоматизацию!

## Дополнительно

- [Документация n8n](https://docs.n8n.io/)
- [Документация Docker Compose](https://docs.docker.com/compose/)
- [Let's Encrypt документация](https://letsencrypt.org/docs/)
