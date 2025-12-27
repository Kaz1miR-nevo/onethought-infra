# OneThought VPS Deployment

Ця директорія містить всі необхідні файли для деплою OneThought на VPS сервер (HostIQ kVPS50).

## 📁 Структура

```
deploy/vps/
├── README.md                       # Цей файл
├── QUICK-START.md                  # Швидкий старт (5 хвилин)
├── HOSTIQ-DEPLOYMENT-GUIDE.md      # Детальна інструкція для DevOps
├── docker-compose.vps.yml          # Docker Compose конфігурація
├── nginx/
│   └── onethought.conf             # Nginx reverse proxy конфігурація
└── scripts/
    ├── setup-server.sh             # Початкове налаштування сервера
    ├── deploy.sh                   # Скрипт деплою застосунку
    ├── backup.sh                   # Скрипт резервного копіювання
    └── update-ssl.sh               # Оновлення SSL сертифікатів
```

## 🚀 Швидкий старт

1. **Прочитайте** [QUICK-START.md](./QUICK-START.md) для швидкого деплою
2. **Для деталей** - дивіться [HOSTIQ-DEPLOYMENT-GUIDE.md](./HOSTIQ-DEPLOYMENT-GUIDE.md)

## 📋 Вимоги

- **VPS**: HostIQ kVPS50 (4GB RAM, 50GB SSD)
- **ОС**: AlmaLinux 8/9
- **Домен**: налаштований DNS
- **Supabase**: активний проект

## 🔑 Ключові файли

### docker-compose.vps.yml
Основна конфігурація Docker Compose для запуску:
- OneThought Web (Next.js) на порту 3000
- onethought-api (Fastify) на порту 3001

### nginx/onethought.conf
Nginx конфігурація для:
- Reverse proxy до Docker контейнерів
- SSL termination (Let's Encrypt)
- Rate limiting
- Security headers

### scripts/setup-server.sh
Автоматичне налаштування сервера:
- Встановлення Docker, Nginx, Certbot
- Налаштування firewall та fail2ban
- Створення структури директорій

### scripts/deploy.sh
Скрипт деплою застосунку:
- Побудова Docker образів
- Запуск контейнерів
- Перевірка health checks

## 📝 Checklist перед деплоєм

- [ ] VPS сервер активний та доступний
- [ ] DNS записи налаштовані
- [ ] Supabase проект готовий
- [ ] Змінні оточення (.env.production) налаштовані
- [ ] SSL сертифікати отримані
- [ ] Firewall налаштований

## 🔧 Після деплою

- Перевірте статус: `docker compose ps`
- Перегляньте логи: `docker compose logs -f`
- Налаштуйте автоматичні backup
- Налаштуйте SSL auto-renewal

## 📚 Документація

- **Детальна інструкція**: [HOSTIQ-DEPLOYMENT-GUIDE.md](./HOSTIQ-DEPLOYMENT-GUIDE.md)
- **Швидкий старт**: [QUICK-START.md](./QUICK-START.md)

## ⚠️ Важливо

1. **НЕ комітьте** `.env.production` файли в git
2. **Завжди** використовуйте production змінні для production середовища
3. **Регулярно** робіть backup конфігурацій та логів
4. **Моніторьте** використання ресурсів (RAM, CPU, диск)



