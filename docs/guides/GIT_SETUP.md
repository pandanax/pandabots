# 🔧 Настройка Git репозитория

> Инструкция по подключению проекта к удаленному Git репозиторию

## ✅ Проект готов к git!

Все чувствительные данные исключены из git через `.gitignore`.

## 📋 Что уже сделано

- ✅ `.gitignore` настроен и проверен
- ✅ Удалены `terraform.tfstate*` файлы  
- ✅ Все чувствительные данные только в `.env` и `terraform.tfvars`
- ✅ Документация очищена от Cloud ID, Folder ID, паролей
- ✅ Пути сделаны относительными
- ✅ Создан `SECURITY.md` с правилами безопасности
- ✅ Создан `PRE_COMMIT_CHECKLIST.md` для проверки перед commit

## 🚀 Подключение к GitHub/GitLab

### Шаг 1: Инициализация git

```bash
cd /Users/pandanax/dev/n8n

# Инициализируй git репозиторий
git init

# Проверь ветку (должна быть main или master)
git branch -M main
```

### Шаг 2: Проверка перед commit

```bash
# Проверь статус
git status

# Добавь все файлы
git add .

# ВАЖНО! Проверь что добавлено
git status

# Убедись что НЕТ в списке:
# - deploy/.env
# - terraform/terraform.tfvars
# - terraform/*.tfstate*
# - *.json (кроме package.json)
```

### Шаг 3: Первый commit

```bash
# Создай первый commit
git commit -m "Initial commit: n8n infrastructure on Yandex Cloud

- Complete Terraform IaC setup
- Docker Compose configuration
- Nginx with SSL/HTTPS
- Documentation and guides
- Scripts for deployment
"
```

### Шаг 4: Подключение remote репозитория

**GitHub:**
```bash
# Создай репозиторий на GitHub (через веб-интерфейс)
# Затем:
git remote add origin https://github.com/your-username/n8n-yandex-cloud.git

# Или с SSH:
git remote add origin git@github.com:your-username/n8n-yandex-cloud.git
```

**GitLab:**
```bash
# Создай репозиторий на GitLab
git remote add origin https://gitlab.com/your-username/n8n-yandex-cloud.git

# Или с SSH:
git remote add origin git@gitlab.com:your-username/n8n-yandex-cloud.git
```

### Шаг 5: Push

```bash
# Push в main ветку
git push -u origin main

# Если нужно force push (первый раз может потребоваться)
# git push -u origin main --force
```

## 🔍 Финальная проверка после push

```bash
# Проверь удаленный репозиторий
git remote -v

# Проверь что запушено
git log --oneline

# Проверь что .env НЕ в репозитории
git ls-files | grep .env
# Должно быть ТОЛЬКО .env.example!

# Проверь что terraform.tfvars НЕ в репозитории  
git ls-files | grep terraform.tfvars
# Должно быть ТОЛЬКО terraform.tfvars.example!
```

## 📝 Рекомендации для README.md репозитория

Добавь в начало README бейдж со статусом:

```markdown
# n8n на Yandex Cloud

![Status](https://img.shields.io/badge/status-active-success)
![Terraform](https://img.shields.io/badge/IaC-Terraform-blue)
![Docker](https://img.shields.io/badge/deployment-Docker-blue)

Production-ready развертывание n8n на Yandex Cloud
```

## 🔐 Настройка секретов для CI/CD (опционально)

Если в будущем захочешь настроить CI/CD (GitHub Actions, GitLab CI):

**GitHub Secrets:**
- Settings → Secrets and variables → Actions
- Добавь:
  - `YC_SERVICE_ACCOUNT_KEY` - содержимое `~/.yc/n8n-sa-key.json`
  - `TF_VAR_cloud_id` - твой cloud ID
  - `TF_VAR_folder_id` - твой folder ID
  - `SSH_PRIVATE_KEY` - приватный SSH ключ

## 🌿 Рекомендуемая структура веток

```
main (production)
  ↓
develop (staging)
  ↓
feature/* (новые фичи)
hotfix/* (срочные исправления)
```

## 📦 .gitattributes (опционально)

Создай `.gitattributes` для правильного определения языков:

```
*.tf linguist-language=HCL
*.md linguist-documentation
*.sh linguist-language=Shell
```

## 🎯 Следующие шаги после push

1. Добавь README бейджи
2. Настрой GitHub/GitLab Issues для TODO
3. Создай Wiki с детальной документацией (опционально)
4. Настрой branch protection rules для main
5. Настрой Pull Request template (опционально)

## ⚠️ Важно помнить

- **НИКОГДА** не коммить `.env` файлы
- **НИКОГДА** не коммить `terraform.tfvars`
- **ВСЕГДА** проверяй `git status` перед commit
- **ВСЕГДА** используй `.env.example` для примеров
- См. [PRE_COMMIT_CHECKLIST.md](PRE_COMMIT_CHECKLIST.md) перед каждым commit

## 🆘 Если случайно запушил секрет

1. **Немедленно смени все секреты!**
2. Очисти git историю (или пересоздай репозиторий)
3. См. [SECURITY.md](SECURITY.md) для деталей

---

**Проект готов к публикации в git!** ✅

Следуй инструкциям выше для подключения к удаленному репозиторию.
