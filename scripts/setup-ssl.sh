#!/bin/bash

# Скрипт для настройки SSL сертификата на сервере
# Использование: ./scripts/setup-ssl.sh YOUR_EMAIL@example.com

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
SERVER_IP="84.252.137.46"
SERVER_USER="ubuntu"
DEPLOY_DIR="/opt/n8n"
DOMAIN="n8n.mandala-app.online"

# Проверка аргументов
if [ -z "$1" ]; then
    echo -e "${RED}❌ Укажите email для Let's Encrypt${NC}"
    echo -e "   Использование: $0 your-email@example.com"
    exit 1
fi

EMAIL="$1"

echo -e "${BLUE}🔒 Настройка SSL для ${DOMAIN}${NC}"
echo -e "${YELLOW}📧 Email: ${EMAIL}${NC}"
echo ""

# Функция для выполнения команд на сервере
ssh_exec() {
    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "$@"
}

echo -e "${BLUE}1️⃣  Проверка DNS...${NC}"
RESOLVED_IP=$(dig +short ${DOMAIN})
if [ "$RESOLVED_IP" != "$SERVER_IP" ]; then
    echo -e "${RED}❌ DNS не настроен правильно${NC}"
    echo -e "   ${DOMAIN} → ${RESOLVED_IP}"
    echo -e "   Ожидается: ${SERVER_IP}"
    exit 1
fi
echo -e "${GREEN}✅ DNS настроен правильно: ${DOMAIN} → ${SERVER_IP}${NC}"

echo ""
echo -e "${BLUE}2️⃣  Запуск Nginx...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && docker compose up -d nginx"
sleep 5

echo ""
echo -e "${BLUE}3️⃣  Проверка доступности домена по HTTP...${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://${DOMAIN}/health" || echo "000")
if [ "$HTTP_CODE" == "200" ]; then
    echo -e "${GREEN}✅ HTTP доступен (код: ${HTTP_CODE})${NC}"
else
    echo -e "${YELLOW}⚠️  HTTP код: ${HTTP_CODE}${NC}"
    echo -e "${YELLOW}⚠️  Продолжаем, но может потребоваться отладка${NC}"
fi

echo ""
echo -e "${BLUE}4️⃣  Получение SSL сертификата...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && docker compose run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email ${EMAIL} \
    --agree-tos \
    --no-eff-email \
    -d ${DOMAIN}"

echo ""
echo -e "${BLUE}5️⃣  Проверка сертификата...${NC}"
if ssh_exec "test -f ${DEPLOY_DIR}/certbot_conf/live/${DOMAIN}/fullchain.pem"; then
    echo -e "${GREEN}✅ Сертификат получен успешно${NC}"
else
    echo -e "${RED}❌ Сертификат не найден${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}6️⃣  Перезапуск Nginx с SSL...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && docker compose restart nginx"

echo ""
echo -e "${BLUE}7️⃣  Запуск Certbot для автоматического обновления...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && docker compose up -d certbot"

echo ""
echo -e "${BLUE}8️⃣  Проверка HTTPS...${NC}"
sleep 5
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${DOMAIN}/" -k || echo "000")
if [ "$HTTPS_CODE" == "200" ] || [ "$HTTPS_CODE" == "302" ] || [ "$HTTPS_CODE" == "401" ]; then
    echo -e "${GREEN}✅ HTTPS работает (код: ${HTTPS_CODE})${NC}"
else
    echo -e "${YELLOW}⚠️  HTTPS код: ${HTTPS_CODE}${NC}"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ SSL настроен успешно!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}🎉 Откройте n8n в браузере:${NC}"
echo -e "   ${GREEN}https://${DOMAIN}${NC}"
echo ""
echo -e "${YELLOW}📝 Сертификат будет автоматически обновляться каждые 12 часов${NC}"
echo ""
