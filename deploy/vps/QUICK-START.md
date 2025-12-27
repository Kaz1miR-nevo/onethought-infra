# OneThought VPS Quick Start Guide

Швидкий старт для деплою OneThought на HostIQ VPS (kVPS50).

## 🚀 Швидкий старт (5 хвилин)

### 1. Підключення до сервера

```bash
ssh root@YOUR_SERVER_IP
```

### 2. Встановлення базового середовища

```bash
# Завантажте та запустіть setup скрипт
curl -o setup-server.sh https://raw.githubusercontent.com/your-repo/main/deploy/vps/scripts/setup-server.sh
chmod +x setup-server.sh
./setup-server.sh
```

### 3. Клонування репозиторіїв

```bash
mkdir -p /opt/onethought
cd /opt/onethought
git clone https://github.com/Kaz1miR-nevo/onepost.git app
git clone https://github.com/Kaz1miR-nevo/onethought-api.git api
```

### 4. Налаштування змінних оточення

```bash
cd /opt/onethought/app
cp .env.example .env.production
nano .env.production  # Заповніть необхідні значення
```

### 5. Налаштування Nginx

```bash
# Копіюємо конфігурацію
cp deploy/vps/nginx/onethought.conf /etc/nginx/sites-available/
ln -s /etc/nginx/sites-available/onethought.conf /etc/nginx/sites-enabled/
nginx -t
```

### 6. Отримання SSL сертифікатів

```bash
certbot certonly --standalone \
  -d birka.one \
  -d www.birka.one \
  -d api.birka.one \
  --email your-email@example.com \
  --agree-tos
```

### 7. Деплой

```bash
cd /opt/onethought/app
chmod +x deploy/vps/scripts/*.sh
./deploy/vps/scripts/deploy.sh
```

### 8. Перевірка

```bash
# Статус
docker compose ps

# Перевірка сайту
curl -I https://birka.one
curl -I https://api.birka.one
```

## 📝 Необхідні змінні оточення

### `.env.production` (Web)

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
NEXT_PUBLIC_SITE_URL=https://birka.one
```

### `.env.production` (API)

```env
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
CORS_ORIGIN=https://birka.one
```

## 🔧 Корисні команди

```bash
# Логи
docker compose logs -f

# Перезапуск
docker compose restart

# Статус
docker compose ps

# Оновлення
git pull && ./deploy/vps/scripts/deploy.sh
```

## ⚠️ Важливо

1. **DNS** - налаштуйте DNS записи ДО отримання SSL сертифікатів
2. **Безпека** - не комітьте `.env.production` файли в git
3. **Ресурси** - kVPS50 має 4GB RAM, розподіліть ресурси відповідно
4. **Backup** - налаштуйте автоматичні backup

---

Для детальної інформації дивіться [HOSTIQ-DEPLOYMENT-GUIDE.md](./HOSTIQ-DEPLOYMENT-GUIDE.md)

