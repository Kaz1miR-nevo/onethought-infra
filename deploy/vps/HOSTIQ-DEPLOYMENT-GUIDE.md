# OneThought Deployment Guide - HostIQ VPS

## 📋 Зміст

1. [Огляд](#огляд)
2. [Вимоги](#вимоги)
3. [Підготовка сервера](#підготовка-сервера)
4. [Налаштування DNS](#налаштування-dns)
5. [Встановлення та конфігурація](#встановлення-та-конфігурація)
6. [Деплой застосунку](#деплой-застосунку)
7. [Налаштування SSL](#налаштування-ssl)
8. [Моніторинг та логування](#моніторинг-та-логування)
9. [Резервне копіювання](#резервне-копіювання)
10. [Обслуговування](#обслуговування)
11. [Troubleshooting](#troubleshooting)

---

## 🎯 Огляд

Цей гайд описує процес деплою OneThought на VPS сервер HostIQ тарифу **kVPS50**.

### Характеристики тарифу kVPS50:
- **CPU**: до 4.52 ГГц
- **RAM**: 4 ГБ
- **Диск**: 50 ГБ SSD
- **Трафік**: необмежений (до 5 ТБ/міс, далі до 10 МБ/с)
- **ОС**: AlmaLinux 8/9 (рекомендовано 9)
- **Доступ**: root

### Архітектура розгортання:

```
┌─────────────────────────────────────────────────────────┐
│                    HostIQ VPS                            │
│                                                          │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   Nginx      │         │   Docker     │             │
│  │ (Port 80/443)│────────▶│   Compose    │             │
│  └──────────────┘         └──────────────┘             │
│         │                       │                       │
│         │              ┌────────┴────────┐             │
│         │              │                 │             │
│         │         ┌────▼────┐      ┌────▼────┐        │
│         │         │  Web    │      │   API   │        │
│         │         │ (3000)  │      │  (3001) │        │
│         │         └─────────┘      └─────────┘        │
│         │              │                 │             │
│         └──────────────┴─────────────────┘             │
│                         │                              │
│                    ┌────▼─────┐                        │
│                    │ Supabase │                        │
│                    │ (External)│                       │
│                    └──────────┘                        │
└─────────────────────────────────────────────────────────┘
```

**Домени:**
- `birka.one` - головний веб-сайт (Next.js)
- `api.birka.one` - REST API (Fastify)

---

## 📦 Вимоги

### На сервері:
- AlmaLinux 8 або 9 (рекомендовано 9)
- Root доступ
- Мінімум 4 ГБ RAM
- Мінімум 50 ГБ дискового простору

### У DevOps:
- SSH клієнт (Terminal, PuTTY, VS Code Remote)
- Базові знання Linux, Docker, Nginx
- Доступ до DNS налаштувань домену

### Зовнішні сервіси:
- Supabase проект (база даних)
- Домен з можливістю налаштування DNS записів

---

## 🛠️ Підготовка сервера

### Крок 1: Підключення до сервера

```bash
ssh root@YOUR_SERVER_IP
```

### Крок 2: Запуск setup скрипту

Скопіюйте файл `deploy/vps/scripts/setup-server.sh` на сервер:

```bash
# На локальній машині
scp deploy/vps/scripts/setup-server.sh root@YOUR_SERVER_IP:/root/

# На сервері
chmod +x /root/setup-server.sh
./setup-server.sh
```

Скрипт виконає:
- ✅ Оновлення системи
- ✅ Встановлення Docker та Docker Compose
- ✅ Встановлення Nginx
- ✅ Встановлення Certbot (Let's Encrypt)
- ✅ Налаштування firewall
- ✅ Налаштування fail2ban
- ✅ Створення структури директорій
- ✅ Налаштування logrotate

**Час виконання:** ~10-15 хвилин

### Крок 3: Створення користувача для роботи (рекомендовано)

```bash
# Створюємо користувача
useradd -m -s /bin/bash onethought
usermod -aG docker onethought
usermod -aG wheel onethought

# Налаштування SSH ключа (на локальній машині)
ssh-copy-id onethought@YOUR_SERVER_IP

# Переключення на нового користувача
su - onethought
```

---

## 🌐 Налаштування DNS

Перед деплоєм необхідно налаштувати DNS записи для доменів.

### Необхідні DNS записи:

| Тип | Ім'я | Значення | TTL |
|-----|------|----------|-----|
| A | `@` | `YOUR_SERVER_IP` | 3600 |
| A | `www` | `YOUR_SERVER_IP` | 3600 |
| A | `api` | `YOUR_SERVER_IP` | 3600 |
| CNAME | `www.birka.one` | `birka.one` | 3600 (опціонально) |

### Перевірка DNS:

```bash
# Перевірка основних записів
dig birka.one +short
dig www.birka.one +short
dig api.birka.one +short

# Або використовуючи nslookup
nslookup birka.one
nslookup api.birka.one
```

**Важливо:** Зачекайте 5-15 хвилин після зміни DNS записів для їх поширення.

---

## ⚙️ Встановлення та конфігурація

> **📋 Перед початком:** Переконайтеся, що ви налаштували Supabase (дивіться [SUPABASE-SETUP.md](./SUPABASE-SETUP.md))

### Крок 1: Клонування репозиторіїв

```bash
# Створюємо директорію для проекту
mkdir -p /opt/onethought
cd /opt/onethought

# Клонуємо OneThought Web
git clone https://github.com/Kaz1miR-nevo/onepost.git app

# Клонуємо onethought-api
git clone https://github.com/Kaz1miR-nevo/onethought-api.git api

# Перевіряємо структуру
tree -L 2 /opt/onethought
```

### Крок 2: Налаштування Supabase

⚠️ **ВАЖЛИВО:** Перед деплоєм потрібно налаштувати Supabase для роботи з новим доменом.

Детальна інструкція: [SUPABASE-SETUP.md](./SUPABASE-SETUP.md)

**Швидкий старт:**
1. Виконайте SQL скрипт: `lib/supabase/HOSTIQ-VPS-SETUP.sql` в Supabase SQL Editor
2. Налаштуйте Auth URLs через Dashboard (дивіться SUPABASE-SETUP.md)
3. Перевірте email templates

### Крок 3: Налаштування змінних оточення

#### Для OneThought Web (`/opt/onethought/app/.env.production`):

```bash
cd /opt/onethought/app
nano .env.production
```

```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://YOUR_SUPABASE_PROJECT.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
DATABASE_URL=postgresql://postgres:[password]@[host]:5432/postgres

# Application
NEXT_PUBLIC_APP_ENV=production
NEXT_PUBLIC_SITE_URL=https://birka.one

# Logging
LOG_LEVEL=info
```

#### Для onethought-api (`/opt/onethought/api/.env.production`):

```bash
cd /opt/onethought/api
nano .env.production
```

```env
# Supabase
SUPABASE_URL=https://YOUR_SUPABASE_PROJECT.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Application
NODE_ENV=production
PORT=3001
HOST=0.0.0.0

# CORS
CORS_ORIGIN=https://birka.one

# Logging
LOG_LEVEL=info
```

**⚠️ Безпека:** Завжди використовуйте `.env.production` файли, які НЕ комітяться в git!

### Крок 4: Копіювання конфігураційних файлів

```bash
# Копіюємо docker-compose
cp /opt/onethought/app/docker-compose.vps.yml /opt/onethought/app/docker-compose.yml

# Копіюємо nginx конфігурацію
cp /opt/onethought/app/deploy/vps/nginx/onethought.conf /etc/nginx/sites-available/onethought.conf

# Створюємо симлінк
ln -s /etc/nginx/sites-available/onethought.conf /etc/nginx/sites-enabled/onethought.conf

# Перевіряємо конфігурацію nginx
nginx -t
```

### Крок 5: Налаштування Docker Compose

Відредагуйте `docker-compose.vps.yml` якщо потрібно змінити ресурси або порти:

```bash
cd /opt/onethought/app
nano docker-compose.vps.yml
```

**Важливі параметри для kVPS50:**
- Web: 2GB RAM, 2 CPU cores
- API: 1.5GB RAM, 1.5 CPU cores
- Загальне використання: ~3.5GB RAM (залишаємо запас)

---

## 🚀 Деплой застосунку

### Крок 1: Отримання SSL сертифікатів (до деплою!)

```bash
# Зупиняємо nginx тимчасово
systemctl stop nginx

# Отримуємо сертифікати
certbot certonly --standalone \
  -d birka.one \
  -d www.birka.one \
  -d api.birka.one \
  --email your-email@example.com \
  --agree-tos \
  --non-interactive

# Запускаємо nginx
systemctl start nginx
```

### Крок 2: Запуск деплою

```bash
cd /opt/onethought/app

# Надаємо права виконання скрипту
chmod +x deploy/vps/scripts/deploy.sh

# Запускаємо деплой
./deploy/vps/scripts/deploy.sh
```

Скрипт виконає:
1. Перевірку середовища
2. Зупинку старих контейнерів
3. Побудову нових Docker образів
4. Запуск контейнерів
5. Перевірку health checks

### Крок 3: Перевірка статусу

```bash
# Статус контейнерів
docker compose ps

# Логи
docker compose logs -f

# Health checks
curl http://localhost:3000/api/health
curl http://localhost:3001/api/v1/health
```

### Крок 4: Перевірка через Nginx

```bash
# Перезавантаження nginx
systemctl reload nginx

# Перевірка через домени
curl -I https://birka.one
curl -I https://api.birka.one
```

---

## 🔒 Налаштування SSL

### Автоматичне оновлення сертифікатів

Let's Encrypt сертифікати дійсні 90 днів. Для автоматичного оновлення:

```bash
# Налаштування cron job
crontab -e

# Додати рядок (оновлення кожні 2 тижні)
0 3 * * 0 /usr/bin/certbot renew --quiet --nginx && systemctl reload nginx
```

Або використовуйте скрипт:

```bash
chmod +x /opt/onethought/app/deploy/vps/scripts/update-ssl.sh
```

---

## 📊 Моніторинг та логування

### Переглянути логи Docker контейнерів:

```bash
# Всі логи
docker compose -f docker-compose.vps.yml logs -f

# Логи конкретного сервісу
docker compose -f docker-compose.vps.yml logs -f web
docker compose -f docker-compose.vps.yml logs -f api

# Останні 100 рядків
docker compose -f docker-compose.vps.yml logs --tail=100
```

### Переглянути логи Nginx:

```bash
# Access logs
tail -f /var/log/nginx/onethought-web-access.log
tail -f /var/log/nginx/onethought-api-access.log

# Error logs
tail -f /var/log/nginx/onethought-web-error.log
tail -f /var/log/nginx/onethought-api-error.log
```

### Моніторинг ресурсів:

```bash
# Використання ресурсів контейнерів
docker stats

# Використання диску
df -h

# Використання пам'яті
free -h

# Навантаження системи
htop
```

### Налаштування моніторингу (опціонально):

Можна встановити Prometheus + Grafana для детального моніторингу, але для kVPS50 це може бути занадто ресурсозатратно. Базовий моніторинг через `docker stats` та системні утиліти достатній.

---

## 💾 Резервне копіювання

### Автоматичне резервне копіювання

Налаштуйте cron job для автоматичних backup:

```bash
# Редагуємо crontab
crontab -e

# Додаємо рядок (backup щодня о 2:00 ночі)
0 2 * * * /opt/onethought/app/deploy/vps/scripts/backup.sh >> /opt/onethought/logs/backup.log 2>&1
```

Скрипт `backup.sh` створює backup:
- Nginx конфігурацій
- Docker Compose та .env файлів
- Логів
- Автоматично видаляє backup старіше 7 днів

### Ручне резервне копіювання:

```bash
cd /opt/onethought/app
./deploy/vps/scripts/backup.sh
```

### Backup Supabase:

Supabase має власну систему резервного копіювання. Перевірте налаштування в панелі Supabase.

---

## 🔧 Обслуговування

### Оновлення застосунку

```bash
cd /opt/onethought/app

# Отримуємо останні зміни
git pull origin main

# Перезапускаємо деплой
./deploy/vps/scripts/deploy.sh
```

### Перезапуск сервісів

```bash
# Перезапуск всіх сервісів
docker compose -f docker-compose.vps.yml restart

# Перезапуск конкретного сервісу
docker compose -f docker-compose.vps.yml restart web
docker compose -f docker-compose.vps.yml restart api

# Перезапуск nginx
systemctl restart nginx
```

### Очищення Docker

```bash
# Видалення невикористовуваних образів
docker image prune -a

# Видалення невикористовуваних volumes
docker volume prune

# Видалення невикористовуваних мереж
docker network prune

# Повна очищення (обережно!)
docker system prune -a --volumes
```

### Оновлення системи

```bash
# Оновлення пакетів
dnf update -y

# Перезавантаження сервера (якщо потрібно)
reboot
```

---

## 🐛 Troubleshooting

### Проблема: Контейнери не запускаються

```bash
# Перевірка логів
docker compose logs

# Перевірка конфігурації
docker compose config

# Перевірка ресурсів
docker stats
free -h
```

### Проблема: Nginx повертає 502 Bad Gateway

```bash
# Перевірка чи працюють контейнери
docker compose ps

# Перевірка health checks
curl http://localhost:3000/api/health
curl http://localhost:3001/api/v1/health

# Перевірка nginx конфігурації
nginx -t

# Перевірка логів nginx
tail -f /var/log/nginx/onethought-web-error.log
```

### Проблема: SSL сертифікат не працює

```bash
# Перевірка сертифікату
openssl s_client -connect birka.one:443 -servername birka.one

# Оновлення сертифікату вручну
certbot renew --nginx --force-renewal

# Перезавантаження nginx
systemctl reload nginx
```

### Проблема: Закінчилася пам'ять

```bash
# Перевірка використання
free -h
docker stats

# Очищення
docker system prune -a

# Якщо критично - зменшити ресурси в docker-compose.vps.yml
```

### Проблема: Занадто багато логів

```bash
# Очищення логів Docker
docker compose logs --tail=0 > /dev/null

# Ротація логів nginx
logrotate -f /etc/logrotate.d/onethought
```

### Корисні команди для діагностики:

```bash
# Статус всіх сервісів
systemctl status docker nginx fail2ban

# Мережеві з'єднання
netstat -tulpn | grep LISTEN
ss -tulpn

# Дискове використання
du -sh /opt/onethought/*
df -h

# Процеси Docker
docker ps -a
docker images
```

---

## 📞 Підтримка

### Логи та діагностика:

Всі логи зберігаються в:
- Docker logs: `docker compose logs`
- Nginx logs: `/var/log/nginx/onethought-*.log`
- System logs: `/var/log/messages`

### Корисні посилання:

- [HostIQ Documentation](https://hostiq.ua/ukr/help/)
- [Docker Documentation](https://docs.docker.com/)
- [Nginx Documentation](https://nginx.org/en/docs/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

---

## ✅ Checklist після деплою

- [ ] Всі контейнери працюють (`docker compose ps`)
- [ ] Health checks проходять (web та api)
- [ ] SSL сертифікати встановлені та працюють
- [ ] Домени доступні через HTTPS
- [ ] Nginx правильно проксує запити
- [ ] Fail2ban активний
- [ ] Firewall налаштований
- [ ] Backup скрипт налаштований
- [ ] SSL auto-renewal налаштований
- [ ] Логування працює
- [ ] Моніторинг ресурсів налаштований

---

**Версія документації:** 1.0  
**Дата оновлення:** 2025-01-XX  
**Автор:** OneThought DevOps Team

