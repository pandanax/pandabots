#!/bin/bash

# Скрипт для развертывания n8n на сервере
# Использование: ./scripts/deploy.sh

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
LOCAL_DEPLOY_DIR="./deploy"

echo -e "${BLUE}🚀 Развертывание n8n на ${SERVER_IP}${NC}"
echo ""

# Проверка наличия deploy директории
if [ ! -d "$LOCAL_DEPLOY_DIR" ]; then
    echo -e "${RED}❌ Директория ${LOCAL_DEPLOY_DIR} не найдена${NC}"
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f "$LOCAL_DEPLOY_DIR/.env" ]; then
    echo -e "${YELLOW}⚠️  Файл .env не найден${NC}"
    echo -e "${YELLOW}📝 Создайте .env файл на основе .env.example${NC}"
    echo -e "${YELLOW}   Команда: cd deploy && cp .env.example .env && nano .env${NC}"
    exit 1
fi

# Функция для выполнения команд на сервере
ssh_exec() {
    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "$@"
}

# Функция для копирования файлов на сервер
scp_copy() {
    scp -o StrictHostKeyChecking=no -r "$@"
}

echo -e "${BLUE}1️⃣  Проверка подключения к серверу...${NC}"
if ! ssh_exec "echo '✅ Подключение успешно'"; then
    echo -e "${RED}❌ Не удалось подключиться к серверу${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}2️⃣  Создание директорий на сервере...${NC}"
ssh_exec "sudo mkdir -p ${DEPLOY_DIR}"
ssh_exec "sudo chown ${SERVER_USER}:${SERVER_USER} ${DEPLOY_DIR}"

echo ""
echo -e "${BLUE}3️⃣  Копирование файлов на сервер...${NC}"
scp_copy ${LOCAL_DEPLOY_DIR}/* ${SERVER_USER}@${SERVER_IP}:${DEPLOY_DIR}/
echo -e "${GREEN}✅ Файлы скопированы${NC}"

echo ""
echo -e "${BLUE}4️⃣  Установка структуры директорий...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && mkdir -p nginx/conf.d"

echo ""
echo -e "${BLUE}5️⃣  Проверка Docker...${NC}"
if ssh_exec "docker --version && docker compose version"; then
    echo -e "${GREEN}✅ Docker готов${NC}"
else
    echo -e "${RED}❌ Docker не установлен или не работает${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}6️⃣  Запуск PostgreSQL и n8n (без SSL)...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && docker compose up -d postgres n8n"

echo ""
echo -e "${YELLOW}⏳ Ожидание инициализации PostgreSQL (30 секунд)...${NC}"
sleep 30

echo ""
echo -e "${BLUE}7️⃣  Проверка статуса контейнеров...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && docker compose ps"

echo ""
echo -e "${BLUE}8️⃣  Проверка логов n8n...${NC}"
ssh_exec "cd ${DEPLOY_DIR} && docker compose logs --tail=20 n8n"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Базовое развертывание завершено!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📝 СЛЕДУЮЩИЕ ШАГИ:${NC}"
echo ""
echo -e "${BLUE}1. Настройте SSL сертификат:${NC}"
echo -e "   ssh ${SERVER_USER}@${SERVER_IP}"
echo -e "   cd ${DEPLOY_DIR}"
echo -e "   docker compose up -d nginx"
echo -e "   docker compose run --rm certbot certonly \\"
echo -e "     --webroot --webroot-path=/var/www/certbot \\"
echo -e "     --email YOUR_EMAIL@example.com \\"
echo -e "     --agree-tos --no-eff-email \\"
echo -e "     -d n8n.mandala-app.online"
echo ""
echo -e "${BLUE}2. Перезапустите nginx после получения сертификата:${NC}"
echo -e "   docker compose restart nginx"
echo ""
echo -e "${BLUE}3. Запустите certbot для автоматического обновления:${NC}"
echo -e "   docker compose up -d certbot"
echo ""
echo -e "${BLUE}4. Откройте n8n в браузере:${NC}"
echo -e "   ${GREEN}https://n8n.mandala-app.online${NC}"
echo ""
echo -e "${YELLOW}📚 Полная документация: deploy/README.md${NC}"
echo ""
