#!/bin/bash

# Скрипт для синхронизации RAG баз знаний на сервер
# Использование: ./scripts/sync-rags.sh [имя-базы]
# Примеры:
#   ./scripts/sync-rags.sh                 # синхронизировать все базы
#   ./scripts/sync-rags.sh fitbot          # синхронизировать только fitbot

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
RAGS_LOCAL_DIR="./rags"
RAGS_SERVER_DIR="/home/node/.n8n-files/rags"
RAGS_TEMP_DIR="/tmp/rags-sync"

echo -e "${BLUE}📦 Синхронизация RAG баз знаний${NC}"
echo ""

# Проверка наличия локальной директории rags
if [ ! -d "$RAGS_LOCAL_DIR" ]; then
    echo -e "${RED}❌ Директория ${RAGS_LOCAL_DIR} не найдена${NC}"
    exit 1
fi

# Функция для выполнения команд на сервере
ssh_exec() {
    ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} "$@"
}

# Проверка подключения к серверу
echo -e "${BLUE}1️⃣  Проверка подключения к серверу...${NC}"
if ! ssh_exec "echo '✅ Подключение успешно'"; then
    echo -e "${RED}❌ Не удалось подключиться к серверу${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}2️⃣  Подготовка директорий на сервере...${NC}"

# Создаём временную директорию на сервере
ssh_exec "rm -rf ${RAGS_TEMP_DIR} && mkdir -p ${RAGS_TEMP_DIR}"

# Создаём целевую директорию если её нет
ssh_exec "sudo mkdir -p ${RAGS_SERVER_DIR}"

# Определяем что синхронизировать
if [ -n "$1" ]; then
    # Синхронизация конкретной базы
    RAG_NAME="$1"
    LOCAL_PATH="${RAGS_LOCAL_DIR}/${RAG_NAME}"
    
    if [ ! -d "$LOCAL_PATH" ]; then
        echo -e "${RED}❌ База знаний '${RAG_NAME}' не найдена в ${RAGS_LOCAL_DIR}/${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}📁 Синхронизация базы: ${RAG_NAME}${NC}"
    echo ""
    
    echo -e "${BLUE}3️⃣  Копирование файлов на сервер...${NC}"
    rsync -avz --progress "$LOCAL_PATH/" ${SERVER_USER}@${SERVER_IP}:${RAGS_TEMP_DIR}/${RAG_NAME}/
    
    echo ""
    echo -e "${BLUE}4️⃣  Перемещение в целевую директорию...${NC}"
    ssh_exec "sudo rm -rf ${RAGS_SERVER_DIR}/${RAG_NAME} && \
              sudo mv ${RAGS_TEMP_DIR}/${RAG_NAME} ${RAGS_SERVER_DIR}/ && \
              sudo chown -R 1000:1000 ${RAGS_SERVER_DIR}/${RAG_NAME}"
    
    echo -e "${GREEN}✅ База '${RAG_NAME}' синхронизирована${NC}"
    
else
    # Синхронизация всех баз
    echo -e "${YELLOW}📁 Синхронизация всех баз знаний${NC}"
    echo ""
    
    echo -e "${BLUE}3️⃣  Копирование файлов на сервер...${NC}"
    rsync -avz --progress --exclude='README.md' --exclude='.DS_Store' \
        "$RAGS_LOCAL_DIR/" ${SERVER_USER}@${SERVER_IP}:${RAGS_TEMP_DIR}/
    
    echo ""
    echo -e "${BLUE}4️⃣  Перемещение в целевую директорию...${NC}"
    ssh_exec "sudo rm -rf ${RAGS_SERVER_DIR}/* && \
              sudo mv ${RAGS_TEMP_DIR}/* ${RAGS_SERVER_DIR}/ && \
              sudo chown -R 1000:1000 ${RAGS_SERVER_DIR}"
    
    echo -e "${GREEN}✅ Все базы знаний синхронизированы${NC}"
fi

echo ""
echo -e "${BLUE}5️⃣  Проверка синхронизации...${NC}"

# Проверяем структуру на сервере
echo -e "${YELLOW}Структура на сервере:${NC}"
ssh_exec "sudo ls -lah ${RAGS_SERVER_DIR}"

echo ""
echo -e "${BLUE}6️⃣  Проверка доступности в контейнере n8n...${NC}"
if ssh_exec "docker ps | grep -q n8n"; then
    echo -e "${YELLOW}Структура в контейнере:${NC}"
    ssh_exec "docker exec n8n ls -lah /home/node/.n8n-files/rags/"
    
    # Проверяем возможность чтения файлов
    echo ""
    echo -e "${YELLOW}Проверка чтения файлов:${NC}"
    
    if [ -n "$1" ]; then
        # Проверяем конкретную базу
        ssh_exec "docker exec n8n test -r /home/node/.n8n-files/rags/${RAG_NAME}/knowledge.txt && echo '✅ ${RAG_NAME}/knowledge.txt - readable' || echo '❌ ${RAG_NAME}/knowledge.txt - not readable'"
    else
        # Проверяем все базы
        ssh_exec "docker exec n8n test -r /home/node/.n8n-files/rags/mandala-bot-advanced/knowledge.txt && echo '✅ mandala-bot-advanced/knowledge.txt - readable' || echo '❌ mandala-bot-advanced/knowledge.txt - not readable'"
        ssh_exec "docker exec n8n test -r /home/node/.n8n-files/rags/fitbot/knowledge.txt && echo '✅ fitbot/knowledge.txt - readable' || echo '❌ fitbot/knowledge.txt - not readable'"
    fi
else
    echo -e "${YELLOW}⚠️  Контейнер n8n не запущен, пропускаем проверку${NC}"
fi

echo ""
echo -e "${BLUE}7️⃣  Очистка временных файлов...${NC}"
ssh_exec "rm -rf ${RAGS_TEMP_DIR}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Синхронизация завершена успешно!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -n "$1" ]; then
    echo -e "${YELLOW}📝 Путь в workflow:${NC}"
    echo -e "   /home/node/.n8n-files/rags/${RAG_NAME}/knowledge.txt"
else
    echo -e "${YELLOW}📝 Пути в workflow:${NC}"
    echo -e "   Mandala Bot: /home/node/.n8n-files/rags/mandala-bot-advanced/knowledge.txt"
    echo -e "   FitBot:      /home/node/.n8n-files/rags/fitbot/knowledge.txt"
fi

echo ""
echo -e "${YELLOW}💡 Совет: Перезапуск контейнера не требуется.${NC}"
echo -e "${YELLOW}   Workflow подхватит изменения при следующем запуске.${NC}"
echo ""
