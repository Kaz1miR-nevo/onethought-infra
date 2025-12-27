# Supabase Configuration для HostIQ VPS Deployment

## 📋 Огляд

Цей документ описує необхідні зміни в Supabase для деплою OneThought на HostIQ VPS з доменом **birka.one**.

## 🔧 Необхідні зміни

### 1. SQL Script - Автоматичні налаштування

Виконайте SQL скрипт в Supabase SQL Editor:

**Production проект:**  
https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/sql/new

**Файл:** `lib/supabase/HOSTIQ-VPS-SETUP.sql`

Цей скрипт:
- ✅ Створює/оновлює таблицю `app_settings` з доменами
- ✅ Перевіряє storage buckets
- ✅ Перевіряє RLS policies
- ✅ Перевіряє критичні функції
- ✅ Створює helper функції для отримання URL

### 2. Auth Configuration - Вручну через Dashboard

#### Крок 1: Відкрийте Auth Settings

Перейдіть до:  
https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/auth/url-configuration

#### Крок 2: Налаштуйте Site URL

```
Site URL: https://birka.one
```

#### Крок 3: Додайте Redirect URLs

Додайте наступні URL до списку **Redirect URLs**:

```
https://birka.one/auth/callback
https://birka.one/**
https://www.birka.one/auth/callback
https://www.birka.one/**
```

**Важливо:** Залиште також старі redirect URLs для stage середовища (якщо воно використовується).

#### Крок 4: Налаштуйте Allowed Origins (CORS)

Додайте до **Additional Redirect URLs** або налаштуйте CORS:

```
https://birka.one
https://www.birka.one
https://api.birka.one
```

### 3. Email Templates - Перевірка

Перейдіть до:  
https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/auth/templates

#### Перевірте шаблони:

1. **Confirm signup** - перевірте, що посилання використовують `birka.one`
2. **Magic Link** - перевірте домен
3. **Change Email Address** - перевірте домен
4. **Reset Password** - перевірте домен

**Приклад зміни в шаблонах:**

Знайдіть застарілі посилання типу:
```
https://stage.onethought.app/auth/callback
```

Замініть на:
```
https://birka.one/auth/callback
```

### 4. API Settings - Перевірка

Перейдіть до:  
https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/settings/api

#### Перевірте:

- ✅ **Project URL**: `https://hutrzgxhgnkkkvwmlytm.supabase.co`
- ✅ **API URL**: `https://hutrzgxhgnkkkvwmlytm.supabase.co`
- ✅ **Service Role Key**: зберігається безпечно (не комітиться в git)

### 5. Storage Buckets - Перевірка

Перейдіть до:  
https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/storage/buckets

#### Перевірте buckets:

- ✅ `avatars` - для аватарів користувачів
- ✅ `post-media` - для медіа в постах

#### Налаштування CORS для Storage:

Якщо потрібно, додайте CORS правила для `birka.one`:

```json
{
  "allowedOrigins": [
    "https://birka.one",
    "https://www.birka.one"
  ],
  "allowedMethods": ["GET", "POST", "PUT", "DELETE"],
  "allowedHeaders": ["*"],
  "maxAge": 3600
}
```

## ✅ Checklist

Після виконання всіх кроків перевірте:

- [ ] SQL скрипт виконано успішно
- [ ] Site URL налаштовано: `https://birka.one`
- [ ] Redirect URLs додано для `birka.one` та `www.birka.one`
- [ ] Allowed Origins налаштовано
- [ ] Email templates оновлені з правильним доменом
- [ ] API settings перевірені
- [ ] Storage buckets перевірені
- [ ] CORS налаштовано для storage (якщо потрібно)

## 🧪 Тестування

### Тест 1: Автентифікація

1. Відкрийте `https://birka.one/login`
2. Спробуйте зареєструватися або увійти
3. Перевірте, що redirect працює коректно

### Тест 2: Email посилання

1. Зареєструйте новий акаунт
2. Перевірте email - посилання має вести на `birka.one`
3. Перевірте reset password flow

### Тест 3: Storage

1. Завантажте аватар
2. Перевірте, що зображення доступне через Supabase Storage
3. Перевірте CORS (якщо налаштовано)

### Тест 4: API

1. Перевірте, що API на `https://api.birka.one` може підключатися до Supabase
2. Перевірте CORS для API запитів

## 🔗 Корисні посилання

- **Supabase Dashboard**: https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm
- **Auth Configuration**: https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/auth/url-configuration
- **Email Templates**: https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/auth/templates
- **API Settings**: https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/settings/api
- **Storage**: https://supabase.com/dashboard/project/hutrzgxhgnkkkvwmlytm/storage/buckets

## 📝 Примітки

1. **Не видаляйте старі redirect URLs** - вони можуть використовуватися для stage середовища
2. **Перевірте email templates** - вони можуть містити hardcoded URLs
3. **CORS налаштування** - деякі налаштування можуть потребувати додаткових змін через Dashboard
4. **Service Role Key** - завжди зберігайте безпечно, не комітьте в git

---

**Версія**: 1.0  
**Дата**: 2025-01-XX  
**Для домену**: birka.one



