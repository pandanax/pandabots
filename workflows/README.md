# n8n Workflows

Эта папка содержит JSON файлы готовых workflow для импорта в n8n.

## 📋 Список workflow

### 1. `telegram-hello-bot.json`
**Описание:** Простой Telegram бот, который отвечает "Здарова!" на любое сообщение  
**Требуемые credentials:** Telegram Bot API Token  
**Инструкция:** [SETUP_TELEGRAM_BOT.md](SETUP_TELEGRAM_BOT.md)

### 2. `telegram-ai-bot.json` ⭐ NEW!
**Описание:** AI-powered Telegram бот с Google Gemini 2.0 Flash  
**Возможности:**
- Умный диалог на русском языке
- Бесплатный tier: 1500 запросов/день
- Настраиваемая личность бота
- Поддержка Markdown в ответах

**Требуемые credentials:**
- Telegram Bot API Token
- Google Gemini API Key

**Инструкция:** [SETUP_GEMINI.md](SETUP_GEMINI.md)

---

## 🔧 Как использовать

### Импорт workflow в n8n:

1. Открой n8n: https://n8n.mandala-app.online
2. Нажми "Add workflow" → "Import from File"
3. Выбери JSON файл из этой папки
4. Настрой credentials (см. ниже)

### Настройка Telegram Bot credentials:

1. В n8n перейди: **Settings** → **Credentials** → **Add Credential**
2. Выбери тип: **Telegram API**
3. Введи данные:
   - **Credential Name:** `Telegram Test Bot` (или любое имя)
   - **Access Token:** Токен от @BotFather
4. Нажми **Save**
5. В workflow выбери этот credential в узлах Telegram

### Webhook URL для Telegram:

После импорта workflow:
1. Скопируй Production Webhook URL из узла "Telegram Trigger"
2. Он будет вида: `https://n8n.mandala-app.online/webhook/telegram-test-bot`
3. n8n автоматически зарегистрирует webhook у Telegram

---

## 🔒 Безопасность

⚠️ **НИКОГДА не коммить файлы с токенами!**

- ✅ JSON workflow (без токенов) - можно в git
- ❌ Токены ботов - только в n8n credentials
- ❌ `.env` файлы с токенами - только локально

---

## 📂 Структура файлов

```
workflows/
├── README.md                    # Этот файл
├── telegram-hello-bot.json      # Простой Telegram бот
└── [другие workflow...]
```

---

## 💡 Полезные ссылки

- **n8n Docs:** https://docs.n8n.io/
- **Telegram Bot API:** https://core.telegram.org/bots/api
- **Создать бота:** https://t.me/BotFather
