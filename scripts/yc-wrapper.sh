#!/bin/bash
# Wrapper скрипт для работы с Yandex Cloud
# Использование: ./scripts/yc-wrapper.sh <команда>

# Активируем профиль Service Account
/Users/pandanax/yandex-cloud/bin/yc config profile activate sa-n8n-bot

# Выполняем команду
/Users/pandanax/yandex-cloud/bin/yc "$@"
