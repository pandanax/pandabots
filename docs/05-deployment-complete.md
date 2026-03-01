# n8n Deployment - Успешно завершено!

**Дата:** 2026-02-01

## Обзор

n8n полностью развернут и работает на `https://n8n.mandala-app.online`

## Что было развернуто

### 1. Инфраструктура (Terraform)
- VM в Yandex Cloud (2 CPU, 4GB RAM, 30GB SSD)
- VPC Network и Subnet
- Static External IP: 84.252.137.46
- Security Group с правилами firewall
- **DNS зона `mandala-app.online` в Yandex Cloud DNS**
- **A-запись `n8n.mandala-app.online` → `84.252.137.46`**

### 2. Приложения (Docker Compose)
- **PostgreSQL 15-alpine** - база данных для n8n
- **n8n 2.4.8** - основное приложение
- **Nginx alpine** - reverse proxy с SSL
- **Certbot** - автоматическое обновление SSL сертификатов

### 3. Безопасность
- UFW firewall на сервере
- Fail2ban для защиты от брутфорса SSH
- SSL/TLS сертификаты Let's Encrypt
- HTTPS с HTTP/2
- Security headers (HSTS, X-Frame-Options, и т.д.)

## Архитектура

```
Internet
    ↓
[Yandex Cloud]
    ↓
84.252.137.46:443 (HTTPS)
    ↓
[Nginx Container]
    ↓ reverse proxy
[n8n Container] ←→ [PostgreSQL Container]
```

## Важные уроки и решения проблем

### Проблема 1: VPN меняет IP адрес
**Симптом:** SSH подключение блокируется после смены IP  
**Причина:** Security Group в Yandex Cloud и UFW на сервере ограничивают SSH  
**Решение:** 
- Временно открыли SSH для всех (0.0.0.0/0)
- Fail2ban обеспечивает защиту от брутфорса
- После деплоя можно ограничить SSH обратно

**Код:**
```hcl
# terraform/terraform.tfvars
allowed_ssh_ip = "0.0.0.0/0"  # Временно для деплоя
```

### Проблема 2: Docker Compose не видит переменные окружения
**Симптом:** PostgreSQL падает с ошибкой "POSTGRES_PASSWORD is not set"  
**Причина:** `.env` файл не был скопирован на сервер  
**Решение:** Обязательно копировать `.env` в директорию с `docker-compose.yml`

**Обновленный deploy.sh:**
```bash
# Копирует ВСЕ файлы из deploy/, включая .env
scp -r ${LOCAL_DEPLOY_DIR}/* ${SERVER_USER}@${SERVER_IP}:${DEPLOY_DIR}/
```

### Проблема 3: "Курица и яйцо" с SSL сертификатом
**Симптом:** Nginx не запускается, выдает ошибку о несуществующем SSL сертификате  
**Причина:** Nginx конфигурация требует SSL сертификат, которого еще нет  
**Решение:** Двухэтапный процесс:

1. **Этап 1:** HTTP-only конфигурация
```nginx
# Временная конфигурация - только HTTP
server {
    listen 80;
    server_name n8n.mandala-app.online;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        proxy_pass http://n8n:5678;
    }
}
```

2. **Получение сертификата:**
```bash
docker run --rm \
  --network n8n_n8n-network \
  -v n8n_certbot_conf:/etc/letsencrypt \
  -v n8n_certbot_www:/var/www/certbot \
  certbot/certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email admin@mandala-app.online \
  --agree-tos \
  -d n8n.mandala-app.online
```

3. **Этап 2:** Включение полной HTTPS конфигурации

### Проблема 4: Let's Encrypt не может получить доступ к challenge файлу
**Симптом:** `404 Not Found` при проверке ACME challenge  
**Причина:** Директория `.well-known/acme-challenge/` не существует в volume  
**Решение:** 
- Nginx использует `root` directive для ACME challenge
- Volume должен быть правильно смонтирован в оба контейнера (nginx и certbot)
- Директория создается автоматически при использовании `--webroot`

## Конфигурационные файлы

### docker-compose.yml
Основные моменты:
- Именованные volumes для данных
- Health checks для всех сервисов
- Depends_on с condition: service_healthy
- Сеть bridge для изоляции

### .env файл
Критически важные переменные:
- `N8N_ENCRYPTION_KEY` - НЕ МЕНЯТЬ после первого запуска!
- `POSTGRES_PASSWORD` - сильный случайный пароль
- `N8N_HOST` - доменное имя

### Nginx конфигурация
Ключевые настройки:
- HTTP → HTTPS redirect
- WebSocket support для n8n
- ACME challenge location
- SSL configuration (Mozilla Modern)
- Security headers

## DNS в Terraform

Создание DNS зоны и записей через IaC:

```hcl
# terraform/dns.tf
resource "yandex_dns_zone" "mandala_app_online" {
  name        = "mandala-app-online"
  zone        = "mandala-app.online."
  public      = true
}

resource "yandex_dns_recordset" "n8n_a_record" {
  zone_id = yandex_dns_zone.mandala_app_online.id
  name    = "n8n.mandala-app.online."
  type    = "A"
  ttl     = 300
  data    = [yandex_vpc_address.n8n_external_ip.external_ipv4_address[0].address]
}
```

## Скрипты автоматизации

### deploy.sh
Основной скрипт развертывания:
1. Проверяет подключение к серверу
2. Создает директории
3. Копирует файлы (включая .env!)
4. Запускает PostgreSQL и n8n
5. Выводит инструкции для настройки SSL

### setup-ssl.sh
Скрипт настройки SSL (не используется, заменен ручным процессом):
- Проблема с docker-compose run и entrypoint
- Лучше использовать прямой `docker run`

## Тестирование

### Проверка DNS
```bash
dig +short n8n.mandala-app.online
# Должен вернуть: 84.252.137.46
```

### Проверка HTTP
```bash
curl -I http://n8n.mandala-app.online/health
# Должен вернуть: 200 OK
```

### Проверка HTTPS
```bash
curl -I https://n8n.mandala-app.online/
# Должен вернуть: HTTP/2 200
```

### Проверка SSL сертификата
```bash
echo | openssl s_client -connect n8n.mandala-app.online:443 -servername n8n.mandala-app.online 2>/dev/null | openssl x509 -noout -dates
```

## Мониторинг

### Статус контейнеров
```bash
ssh ubuntu@84.252.137.46 "cd /opt/n8n && docker compose ps"
```

### Логи
```bash
# n8n логи
docker compose logs -f n8n

# Nginx логи
docker compose logs -f nginx

# Все логи
docker compose logs -f

# PostgreSQL логи (Managed PostgreSQL)
# Смотреть через Yandex Cloud Console:
# https://console.cloud.yandex.ru/folders/b1g8dn4l2a7t5r1g7i1k/managed-postgresql/cluster/
```

### Использование ресурсов
```bash
# На сервере
docker stats

# Disk usage
docker system df
```

## Резервное копирование

### PostgreSQL (Managed PostgreSQL)

**Yandex Cloud автоматически создаёт бэкапы Managed PostgreSQL каждый день.**

Ручной бэкап:
```bash
cd /Users/pandanax/dev/n8n/scripts

# Использовать helper-скрипт для бэкапа
yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
pg_dump -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n
" > n8n_backup_$(date +%Y%m%d).sql
```

### n8n данные

```bash
# Бэкап через Docker volume
docker compose exec n8n tar czf /tmp/n8n-data.tar.gz /home/node/.n8n
docker compose cp n8n:/tmp/n8n-data.tar.gz ./n8n-data-backup.tar.gz
```

### Восстановление

```bash
# PostgreSQL
cat n8n_backup_20260206.sql | yc compute ssh --name n8n-server -- "
PGPASSWORD='6YURjrx7UP5VarHZ8VJSM7pCGD2khVPT' \
psql -h rc1b-fu6im376hu9oc1lb.mdb.yandexcloud.net -p 6432 -U n8n -d n8n
"

# n8n данные
docker compose cp n8n-data-backup.tar.gz n8n:/tmp/
docker compose exec n8n tar xzf /tmp/n8n-data-backup.tar.gz -C /
docker compose restart n8n
```

## Обновления

### Обновление n8n
```bash
cd /opt/n8n
docker compose pull n8n
docker compose up -d n8n
```

### Обновление PostgreSQL (Managed PostgreSQL)

⚠️ **Yandex Managed PostgreSQL обновляется автоматически** через консоль Yandex Cloud.

Обновление через Yandex Cloud Console:
1. Открой https://console.cloud.yandex.ru/
2. Managed PostgreSQL → выбери кластер
3. Settings → PostgreSQL version
4. Выбери новую версию и примени

**Yandex автоматически создаст бэкап перед обновлением.**

## Стоимость

**Месячная стоимость (примерно):**
- VM (2 CPU, 4GB RAM): ~4500 руб/мес
- Disk (30GB SSD): ~300 руб/мес
- External IP (статический): ~200 руб/мес
- Egress traffic (примерно): ~500 руб/мес

**Итого:** ~5500-6500 руб/мес

## Следующие шаги

1. ✅ Открыть https://n8n.mandala-app.online в браузере
2. ✅ Создать admin аккаунт
3. Настроить первый workflow
4. Настроить регулярные бэкапы
5. Настроить мониторинг (опционально)
6. Ограничить SSH доступ (когда не используешь VPN)

## Полезные ссылки

- [Документация n8n](https://docs.n8n.io/)
- [Yandex Cloud DNS](https://cloud.yandex.ru/docs/dns/)
- [Let's Encrypt](https://letsencrypt.org/)
- [Docker Compose](https://docs.docker.com/compose/)

---

**Проект завершен успешно!** 🎉
**URL:** https://n8n.mandala-app.online
**Статус:** 🟢 РАБОТАЕТ
