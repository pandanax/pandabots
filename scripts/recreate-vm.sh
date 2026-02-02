#!/bin/bash
# Скрипт для безопасного пересоздания ВМ
set -e

echo "🔄 Пересоздание ВМ с установкой пароля для Serial Console"
echo ""

cd "$(dirname "$0")/../terraform"

echo "1️⃣ Удаление старой ВМ (данные PostgreSQL в безопасности!)..."
terraform destroy -target=yandex_compute_instance.n8n_vm -auto-approve

echo ""
echo "2️⃣ Создание новой ВМ с паролем..."
terraform apply -auto-approve

echo ""
echo "✅ ГОТОВО!"
echo ""
echo "📋 Данные для Serial Console:"
echo "   URL: https://console.yandex.cloud/folders/b1gmrr5e6bncvoin732o/compute/instances"
echo "   Логин: ubuntu"
echo "   Пароль: ChangeMeAfterFirstLogin!"
echo ""
echo "📋 Данные для PostgreSQL (обнови в .env):"
terraform output postgres_host
terraform output postgres_connection_string
