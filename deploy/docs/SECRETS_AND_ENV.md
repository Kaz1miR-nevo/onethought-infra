# Secrets and Environment Variables Guide

## 🔐 Security Principles

1. **Never commit `.env` files to git**
2. **Use different secrets for stage and production**
3. **Rotate secrets regularly**
4. **Restrict file permissions**: `chmod 600 env/*.env`
5. **Store backups securely** (encrypted, separate location)

## 📁 File Locations

Environment files are stored in:
```
/opt/onethought-infra/deploy/env/
├── stage.api.env      # Stage API secrets
├── stage.web.env      # Stage Web secrets
├── prod.api.env       # Production API secrets
└── prod.web.env       # Production Web secrets
```

## 📋 Required Variables

### Stage API (`stage.api.env`)

```bash
# Server
NODE_ENV=production
PORT=3001
HOST=0.0.0.0
LOG_LEVEL=info

# Supabase (Stage)
SUPABASE_URL=https://cgiqlvscetphwvvffdlj.supabase.co
SUPABASE_ANON_KEY=<your_stage_anon_key>
SUPABASE_SERVICE_ROLE_KEY=<your_stage_service_key>

# JWT Secret (generate: openssl rand -base64 32)
JWT_SECRET=<min_32_characters>

# CORS
CORS_ORIGIN=https://stage.domain.com,http://localhost:3000

# Rate Limiting
RATE_LIMIT_MAX=100
RATE_LIMIT_TIME_WINDOW=60000

# API Version
API_VERSION=v1

# Redis (optional)
REDIS_URL=redis://redis:6379
REDIS_DB=0
```

### Stage Web (`stage.web.env`)

```bash
# Environment
NODE_ENV=production
NEXT_PUBLIC_APP_ENV=stage

# Supabase (Stage)
NEXT_PUBLIC_SUPABASE_URL=https://cgiqlvscetphwvvffdlj.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your_stage_anon_key>
SUPABASE_SERVICE_ROLE_KEY=<your_stage_service_key>

# Site URLs
NEXT_PUBLIC_SITE_URL=https://stage.domain.com
NEXT_PUBLIC_API_URL=https://stage.domain.com/api

# Database (optional, for migrations)
DATABASE_URL=<your_stage_database_url>
```

### Production API (`prod.api.env`)

```bash
# Server
NODE_ENV=production
PORT=3001
HOST=0.0.0.0
LOG_LEVEL=info

# Supabase (Production)
SUPABASE_URL=https://hutrzgxhgnkkkvwmlytm.supabase.co
SUPABASE_ANON_KEY=<your_prod_anon_key>
SUPABASE_SERVICE_ROLE_KEY=<your_prod_service_key>

# JWT Secret (MUST be different from stage!)
JWT_SECRET=<min_32_characters_different_from_stage>

# CORS
CORS_ORIGIN=https://domain.com

# Rate Limiting
RATE_LIMIT_MAX=100
RATE_LIMIT_TIME_WINDOW=60000

# API Version
API_VERSION=v1

# Redis (optional)
REDIS_URL=redis://redis:6379
REDIS_DB=1
```

### Production Web (`prod.web.env`)

```bash
# Environment
NODE_ENV=production
NEXT_PUBLIC_APP_ENV=prod

# Supabase (Production)
NEXT_PUBLIC_SUPABASE_URL=https://hutrzgxhgnkkkvwmlytm.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=<your_prod_anon_key>
SUPABASE_SERVICE_ROLE_KEY=<your_prod_service_key>

# Site URLs
NEXT_PUBLIC_SITE_URL=https://domain.com
NEXT_PUBLIC_API_URL=https://domain.com/api

# Database (optional, for migrations)
DATABASE_URL=<your_prod_database_url>
```

## 🔑 How to Get Secrets

### Supabase Keys

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Select your project (Stage or Production)
3. Go to **Settings** → **API**
4. Copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** → `SUPABASE_ANON_KEY` / `NEXT_PUBLIC_SUPABASE_ANON_KEY`
   - **service_role** → `SUPABASE_SERVICE_ROLE_KEY`

### JWT Secret

Generate a secure random string:
```bash
openssl rand -base64 32
```

**⚠️ IMPORTANT**: Use different JWT secrets for stage and production!

### Database URL

1. Go to Supabase Dashboard
2. **Settings** → **Database**
3. Copy **Connection string** (URI format)
4. Use as `DATABASE_URL` (optional, only for migrations)

## 🛠️ Setup Procedure

1. **Copy example files**
   ```bash
   cd /opt/onethought-infra/deploy/env
   cp stage.api.env.example stage.api.env
   cp stage.web.env.example stage.web.env
   cp prod.api.env.example prod.api.env
   cp prod.web.env.example prod.web.env
   ```

2. **Edit files and fill in values**
   ```bash
   nano stage.api.env
   # ... fill in all values
   ```

3. **Set secure permissions**
   ```bash
   chmod 600 env/*.env
   ```

4. **Verify no secrets in git**
   ```bash
   git status
   # Should NOT show .env files
   ```

## 🔄 Updating Secrets

### Rotate JWT Secret

1. **Generate new secret**
   ```bash
   openssl rand -base64 32
   ```

2. **Update env file**
   ```bash
   nano /opt/onethought-infra/deploy/env/stage.api.env
   # Update JWT_SECRET
   ```

3. **Restart services**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml restart api
   ```

### Update Supabase Keys

1. **Get new keys from Supabase dashboard**
2. **Update env files**
3. **Restart services**

## 💾 Backup

### Backup Environment Files

```bash
# Create encrypted backup
tar -czf env-backup-$(date +%Y%m%d).tar.gz /opt/onethought-infra/deploy/env/
gpg -c env-backup-*.tar.gz  # Encrypt with GPG

# Store backup securely (not on the server!)
```

### Restore from Backup

```bash
# Decrypt
gpg -d env-backup-*.tar.gz > env-backup.tar.gz

# Extract
tar -xzf env-backup.tar.gz -C /
```

## ✅ Validation Checklist

Before deploying, verify:

- [ ] All required variables are set
- [ ] No placeholder values (`<...>`) remain
- [ ] Stage and prod use different secrets
- [ ] File permissions are `600`
- [ ] `.env` files are in `.gitignore`
- [ ] Backups are created and stored securely

## 🚨 If Secrets Are Compromised

1. **Immediately rotate all secrets**
2. **Revoke old Supabase keys** (generate new ones)
3. **Update all environment files**
4. **Restart all services**
5. **Review access logs** for unauthorized access
6. **Notify team**

