# 🚀 Спрощений Гайд Деплою - OneThought на HostIQ VPS

## ⏱️ Оцінка часу та складності

| Етап | Час | Складність | Автоматизація |
|------|-----|------------|---------------|
| **1. Підготовка сервера** | 10-15 хв | ⭐ Легко | ✅ Автоматично (скрипт) |
| **2. Налаштування DNS** | 5 хв | ⭐ Легко | ❌ Вручну (в панелі домену) |
| **3. Налаштування Supabase** | 10-15 хв | ⭐⭐ Середньо | ✅ Частково (SQL скрипт) |
| **4. Клонування репозиторіїв** | 2 хв | ⭐ Легко | ✅ Автоматично (git) |
| **5. Налаштування .env** | 5 хв | ⭐ Легко | ❌ Вручну (копіювання ключів) |
| **6. Отримання SSL** | 5 хв | ⭐ Легко | ✅ Автоматично (certbot) |
| **7. Деплой** | 10-15 хв | ⭐ Легко | ✅ Автоматично (скрипт) |
| **Всього** | **~50-60 хвилин** | **⭐ Легко** | **80% автоматизовано** |

---

## 📋 Покрокова інструкція (для новачків)

### ✅ Крок 0: Перед початком (зробити заздалегідь)

**На вашому комп'ютері:**
1. ✅ Замовте VPS на HostIQ (тариф kVPS50)
2. ✅ Замовте домен (якщо ще немає) - `birka.one`
3. ✅ Переконайтеся, що Supabase проект готовий
4. ✅ Переконайтеся, що у вас є доступ до DNS налаштувань домену

**Потрібні дані:**
- IP адреса VPS сервера
- Логін та пароль root для VPS
- Supabase credentials (URL, anon key, service key)
- Доступ до панелі управління доменом

---

### 🎯 Крок 1: Підключення до сервера (5 хв)

**Відкрийте Terminal (Mac/Linux) або PuTTY (Windows):**

```bash
ssh root@YOUR_SERVER_IP
# Введіть пароль, який вам надав HostIQ
```

**Якщо перший раз підключаєтесь, підтвердіть:**
```
Are you sure you want to continue connecting (yes/no)? yes
```

---

### 🤖 Крок 2: Автоматичне налаштування сервера (15 хв)

**На сервері виконайте:**

```bash
# Завантажте setup скрипт з GitHub
curl -o setup-server.sh https://raw.githubusercontent.com/Kaz1miR-nevo/onepost/main/deploy/vps/scripts/setup-server.sh

# Або скопіюйте з вашого комп'ютера:
# scp deploy/vps/scripts/setup-server.sh root@YOUR_SERVER_IP:/root/

# Додайте права виконання
chmod +x setup-server.sh

# Запустіть (це займе ~10-15 хвилин)
./setup-server.sh
```

**Що робить скрипт:**
- ✅ Оновлює систему
- ✅ Встановлює Docker та Docker Compose
- ✅ Встановлює Nginx
- ✅ Встановлює Certbot (для SSL)
- ✅ Налаштовує firewall
- ✅ Створює структуру директорій

**Після завершення:** Перезавантажте SSH сесію або виконайте `newgrp docker`

---

### 🌐 Крок 3: Налаштування DNS (5 хв)

**У панелі управління вашого домену додайте A записи:**

| Тип | Ім'я | Значення | TTL |
|-----|------|----------|-----|
| A | `@` | `YOUR_SERVER_IP` | 3600 |
| A | `www` | `YOUR_SERVER_IP` | 3600 |
| A | `api` | `YOUR_SERVER_IP` | 3600 |

**Перевірка (через 5-15 хвилин):**
```bash
dig birka.one +short
# Має повернути ваш IP
```

---

### 💾 Крок 4: Налаштування Supabase (15 хв)

#### 4.1. Виконайте SQL скрипт

1. Відкрийте: https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/sql/new
2. Скопіюйте вміст файлу `lib/supabase/HOSTIQ-VPS-SETUP.sql`
3. Вставте в SQL Editor
4. Натисніть "Run"

#### 4.2. Налаштуйте Auth URLs

1. Відкрийте: https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/auth/url-configuration
2. **Site URL:** `https://birka.one`
3. **Redirect URLs:** Додайте:
   - `https://birka.one/auth/callback`
   - `https://www.birka.one/auth/callback`
   - `http://localhost:3000/auth/callback` (для локальної розробки)

Детальна інструкція: [SUPABASE-SETUP.md](./SUPABASE-SETUP.md)

---

### 📥 Крок 5: Клонування репозиторіїв (5 хв)

```bash
# Створюємо директорію
mkdir -p /opt/onethought
cd /opt/onethought

# Клонуємо Web
git clone https://github.com/Kaz1miR-nevo/onepost.git app

# Клонуємо API
git clone https://github.com/Kaz1miR-nevo/onethought-api.git api
```

---

### ⚙️ Крок 6: Налаштування .env файлів (10 хв)

#### 6.1. Для Web (`/opt/onethought/app/.env.production`):

```bash
cd /opt/onethought/app
nano .env.production
```

**Вставте (замініть xxx на реальні значення):**
```env
# Supabase
NEXT_PUBLIC_SUPABASE_URL=https://hutrzgxhgnkkkvwmlytm.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
DATABASE_URL=postgresql://postgres:[password]@db.hutrzgxhgnkkkvwmlytm.supabase.co:5432/postgres

# Application
NEXT_PUBLIC_APP_ENV=production
NEXT_PUBLIC_SITE_URL=https://birka.one

# Logging
LOG_LEVEL=info
```

**Збережіть:** `Ctrl+O`, `Enter`, `Ctrl+X`

#### 6.2. Для API (`/opt/onethought/api/.env.production`):

```bash
cd /opt/onethought/api
nano .env.production
```

**Вставте:**
```env
# Supabase
SUPABASE_URL=https://hutrzgxhgnkkkvwmlytm.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# Application
NODE_ENV=production
PORT=3001
HOST=0.0.0.0

# CORS
CORS_ORIGIN=https://birka.one

# Logging
LOG_LEVEL=info
```

---

### 🔒 Крок 7: Отримання SSL сертифікатів (5 хв)

```bash
# Переконайтеся, що DNS вже налаштовано (перевірте dig birka.one)

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

---

### 🔧 Крок 8: Налаштування Nginx (5 хв)

```bash
cd /opt/onethought/app

# Копіюємо конфігурацію
cp deploy/vps/nginx/onethought.conf /etc/nginx/sites-available/onethought.conf

# Створюємо симлінк
ln -s /etc/nginx/sites-available/onethought.conf /etc/nginx/sites-enabled/onethought.conf

# Перевіряємо конфігурацію
nginx -t

# Якщо все ОК - перезавантажуємо
systemctl reload nginx
```

---

### 🚀 Крок 9: Деплой застосунку (15 хв)

```bash
cd /opt/onethought/app

# Додаємо права виконання
chmod +x deploy/vps/scripts/*.sh

# Запускаємо деплой (це побудує Docker образи та запустить контейнери)
./deploy/vps/scripts/deploy.sh
```

**Це займе ~10-15 хвилин** (будування Docker образів)

---

### ✅ Крок 10: Перевірка (2 хв)

```bash
# Перевірка статусу контейнерів
docker compose -f docker-compose.vps.yml ps

# Перевірка логів (якщо щось не працює)
docker compose -f docker-compose.vps.yml logs

# Перевірка через браузер
# Відкрийте: https://birka.one
# Відкрийте: https://api.birka.one/api/v1/health
```

---

## 🎉 Готово!

Якщо все пройшло успішно, ваш сайт повинен працювати на `https://birka.one`

---

## ❓ Якщо щось пішло не так

### Проблема: Контейнери не запускаються

```bash
# Перевірте логи
docker compose -f docker-compose.vps.yml logs

# Перевірте .env файли
cat /opt/onethought/app/.env.production
```

### Проблема: 502 Bad Gateway

```bash
# Перевірте чи працюють контейнери
docker compose -f docker-compose.vps.yml ps

# Перевірте health checks
curl http://localhost:3000/api/health
curl http://localhost:3001/api/v1/health
```

### Проблема: SSL не працює

```bash
# Перевірте сертифікати
ls -la /etc/letsencrypt/live/birka.one/

# Перевірте nginx конфігурацію
nginx -t
```

**Детальний Troubleshooting:** дивіться [HOSTIQ-DEPLOYMENT-GUIDE.md](./HOSTIQ-DEPLOYMENT-GUIDE.md) розділ "Troubleshooting"

---

## 🔄 Оновлення застосунку в майбутньому

```bash
cd /opt/onethought/app

# Отримати останні зміни
git pull

# Перезапустити деплой
./deploy/vps/scripts/deploy.sh
```

**Це займе ~5-10 хвилин** при наступних деплоях.

---

## 💡 Поради

1. **Перший раз** - виділіть 1-2 години (з урахуванням можливих проблем)
2. **Наступні деплої** - 5-10 хвилин (тільки git pull + deploy)
3. **Backup** - налаштуйте автоматичні backup (вже є скрипт)
4. **Моніторинг** - перевіряйте `docker stats` перші дні

---

## 📚 Корисні посилання

- **Детальна інструкція:** [HOSTIQ-DEPLOYMENT-GUIDE.md](./HOSTIQ-DEPLOYMENT-GUIDE.md)
- **Supabase налаштування:** [SUPABASE-SETUP.md](./SUPABASE-SETUP.md)
- **Швидкий старт:** [QUICK-START.md](./QUICK-START.md)

---

**Всього часу:** ~50-60 хвилин (при першому деплої)  
**Складність:** ⭐ Легко (80% автоматизовано)



