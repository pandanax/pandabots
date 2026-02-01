# n8n на Yandex Cloud

> Production-ready развертывание системы автоматизации n8n с полной автоматизацией через Terraform и Docker Compose

**Статус:** 🟢 РАБОТАЕТ  
**URL:** https://n8n.mandala-app.online  
**Версия:** n8n 2.4.8, PostgreSQL 15, Nginx + SSL

---

## 🚀 Быстрый старт

### Доступ к n8n
```
https://n8n.mandala-app.online
```

### SSH на сервер
```bash
ssh ubuntu@84.252.137.46
```

### Управление
```bash
cd /opt/n8n
docker compose ps              # Статус
docker compose logs -f n8n     # Логи
```

См. [docs/guides/QUICK_START.md](docs/guides/QUICK_START.md) для всех команд.

---

## 📊 Текущий статус

**См. [STATUS.md](STATUS.md)** - там актуальная информация:
- Что работает
- Что в процессе
- Планы на будущее
- Уроки и решения проблем

---

## 📚 Документация

**Главный индекс:** [docs/README.md](docs/README.md)

### Для быстрого старта:
- **[docs/guides/QUICK_START.md](docs/guides/QUICK_START.md)** - основные команды
- **[docs/05-deployment-complete.md](docs/05-deployment-complete.md)** - как всё развёрнуто

### Для разработки:
- **[docs/reference/DATA_LOCATIONS.md](docs/reference/DATA_LOCATIONS.md)** - где какие данные
- **[docs/guides/PRE_COMMIT_CHECKLIST.md](docs/guides/PRE_COMMIT_CHECKLIST.md)** - перед commit
- **[docs/reference/SECURITY.md](docs/reference/SECURITY.md)** - безопасность

### Для AI агента:
- **[AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md)** - входная точка для AI

---

## 🏗️ Архитектура

```
Internet → Yandex Cloud DNS → 84.252.137.46
                                    ↓
                        [Yandex Cloud Security Group]
                                    ↓
                    [VM: Ubuntu 22.04, 2CPU, 4GB RAM]
                                    ↓
                         [Docker Compose Stack]
                        ├─ Nginx (reverse proxy + SSL)
                        ├─ n8n (workflow automation)
                        ├─ PostgreSQL (database)
                        └─ Certbot (SSL renewal)
```

---

## 🛠️ Технологии

| Компонент | Технология | Версия |
|-----------|------------|--------|
| **IaC** | Terraform | latest |
| **Cloud** | Yandex Cloud | - |
| **OS** | Ubuntu | 22.04 LTS |
| **Containers** | Docker Compose | v5.0.2 |
| **Web Server** | Nginx | alpine |
| **SSL** | Let's Encrypt | auto-renew |
| **Database** | PostgreSQL | 15-alpine |
| **App** | n8n | 2.4.8 |

---

## 💡 Ключевые особенности

### Infrastructure as Code
Вся инфраструктура описана в Terraform:
- VM, Network, Security Groups
- DNS зона и A-записи
- Всё в коде, легко воспроизвести

### Безопасность
- SSL/HTTPS с автоматическим обновлением
- UFW firewall + Fail2ban
- PostgreSQL изолирован в Docker network
- Security headers (HSTS, XSS Protection)

### Автоматизация
- Скрипты для развертывания
- Docker Compose для управления
- Certbot для SSL renewal

---

## 📂 Структура проекта

```
.
├── README.md            # ← Ты здесь
├── STATUS.md            # Текущий статус
├── AI_AGENT_GUIDE.md    # Для AI агентов
│
├── docs/                # 📚 Вся документация
│   ├── 01-05-*.md       # История развертывания
│   ├── guides/          # Гайды и инструкции
│   └── reference/       # Справочники
│
├── terraform/           # Infrastructure as Code
│   ├── *.tf             # Конфигурация
│   └── terraform.tfvars # (не в git!)
│
├── deploy/              # Docker Compose
│   ├── docker-compose.yml
│   ├── .env             # (не в git!)
│   └── nginx/
│
├── scripts/             # Автоматизация
└── .local/              # Локальные данные (не в git!)
```

---

## 🎯 Что дальше?

### Использование n8n:
1. Открой https://n8n.mandala-app.online
2. Создай admin аккаунт
3. Начинай автоматизировать!

### Для разработки:
- Читай [docs/README.md](docs/README.md)
- Используй [docs/guides/QUICK_START.md](docs/guides/QUICK_START.md)
- Проверяй [STATUS.md](STATUS.md)

### Для клонирования проекта:
1. Создай `deploy/.env` из `deploy/.env.example`
2. Создай `terraform/terraform.tfvars` из примера
3. Следуй [docs/05-deployment-complete.md](docs/05-deployment-complete.md)

---

## 🤖 Для AI агентов

Если ты AI агент:
1. Читай **[AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md)** первым
2. Затем **[STATUS.md](STATUS.md)**
3. Используй [docs/](docs/) по необходимости

---

## 💰 Стоимость

~6000-7000 руб/мес (2 CPU, 4GB RAM, 30GB SSD, External IP)

---

## 🆘 Troubleshooting

### n8n не отвечает
```bash
ssh ubuntu@84.252.137.46
cd /opt/n8n
docker compose ps
docker compose logs n8n
```

### SSL проблемы
```bash
docker compose logs nginx
docker exec n8n-nginx ls -la /etc/letsencrypt/live/
```

### Полная документация
См. [docs/05-deployment-complete.md](docs/05-deployment-complete.md) - там все решения проблем.

---

## 📞 Ссылки

- **n8n:** https://n8n.mandala-app.online
- **Yandex Cloud:** https://console.cloud.yandex.ru
- **n8n Docs:** https://docs.n8n.io/

---

**Создано:** 2026-01-31  
**Последнее обновление:** 2026-02-01 16:50 UTC+3  
**Статус:** 🟢 Работает  
**Git:** Готов к публикации
