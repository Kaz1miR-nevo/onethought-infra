# DigitalOcean VPS Deployment

This directory contains everything needed to deploy OneThought on a single DigitalOcean VPS.

## 🎯 Quick Start

See [QUICK_START.md](QUICK_START.md) for a step-by-step checklist.

## 📁 Directory Structure

```
deploy/
├── docker-compose.stage.yml    # Stage environment compose file
├── docker-compose.prod.yml      # Production environment compose file
├── env/                         # Environment variable templates
│   ├── stage.api.env.example   # Copy to stage.api.env and fill
│   ├── stage.web.env.example   # Copy to stage.web.env and fill
│   ├── prod.api.env.example    # Copy to prod.api.env and fill
│   └── prod.web.env.example    # Copy to prod.web.env and fill
├── nginx/                       # Nginx configurations
│   ├── stage.conf              # Stage server block
│   ├── prod.conf               # Production server block
│   └── snippets/               # Shared snippets
│       ├── security-headers.conf
│       ├── gzip.conf
│       ├── rate-limit.conf
│       └── websocket.conf
├── redis/                       # Redis configuration
│   └── redis.conf
├── scripts/                     # Deployment scripts
│   ├── 00_server_bootstrap.sh  # Initial server setup
│   ├── 01_install_docker.sh    # Docker installation
│   ├── 02_configure_firewall.sh # UFW setup
│   ├── 03_setup_nginx.sh       # Nginx installation
│   ├── 04_setup_https_certbot.sh # SSL certificates
│   ├── 05_deploy_stage.sh      # Deploy stage
│   ├── 06_deploy_prod.sh       # Deploy production
│   ├── 07_healthcheck.sh       # Health checks
│   └── 08_rollback.sh          # Rollback script
├── docs/                        # Documentation
│   ├── DEPLOY_DO_VPS.md        # Complete guide
│   ├── RUNBOOK.md              # Operations
│   ├── SECRETS_AND_ENV.md      # Environment variables
│   ├── REDIS_USAGE_GUIDE.md    # Redis usage
│   └── MIGRATION_FUTURE_AWS_K8S.md # Future migration
├── QUICK_START.md              # Quick reference
└── DEPLOYMENT_SUMMARY.md       # Summary of changes
```

## 🚀 Deployment Steps

### 1. Prerequisites

- DigitalOcean Droplet (2 vCPU / 4 GB RAM / Ubuntu 22.04)
- Domain names configured (stage.domain.com and domain.com)
- SSH access to the server
- All 3 repositories cloned to `/opt/`:
  - `onethought-infra` → `/opt/onethought-infra`
  - `onethought-api` → `/opt/onethought-api`
  - `onepost` → `/opt/OneThought`

### 2. Bootstrap Server

```bash
cd /opt/onethought-infra/deploy
chmod +x scripts/*.sh

./scripts/00_server_bootstrap.sh
./scripts/01_install_docker.sh
./scripts/02_configure_firewall.sh
./scripts/03_setup_nginx.sh
./scripts/04_setup_https_certbot.sh
```

### 3. Configure Environment

```bash
cd env
cp *.env.example *.env
# Edit each .env file with your secrets
nano stage.api.env
nano stage.web.env
nano prod.api.env
nano prod.web.env
```

### 4. Deploy

```bash
cd ..
./scripts/05_deploy_stage.sh
./scripts/06_deploy_prod.sh
```

### 5. Verify

```bash
./scripts/07_healthcheck.sh
curl https://stage.domain.com/api/health
curl https://domain.com/api/health
```

## 📚 Documentation

- **[QUICK_START.md](QUICK_START.md)** - Quick reference checklist
- **[docs/DEPLOY_DO_VPS.md](docs/DEPLOY_DO_VPS.md)** - Complete deployment guide
- **[docs/RUNBOOK.md](docs/RUNBOOK.md)** - Operational procedures
- **[docs/SECRETS_AND_ENV.md](docs/SECRETS_AND_ENV.md)** - Environment variables guide
- **[docs/REDIS_USAGE_GUIDE.md](docs/REDIS_USAGE_GUIDE.md)** - Redis usage

## 🔧 Common Commands

```bash
# View logs
docker compose -p onethought_stage -f docker-compose.stage.yml logs -f

# Restart services
docker compose -p onethought_stage -f docker-compose.stage.yml restart

# Check status
docker compose -p onethought_stage -f docker-compose.stage.yml ps

# Health check
./scripts/07_healthcheck.sh
```

## ⚠️ Important Notes

1. **Never commit `.env` files** - they contain secrets
2. **All 3 repositories must be cloned** before deployment
3. **Scripts are idempotent** - safe to run multiple times
4. **Redis is optional** but recommended for rate limiting
5. **Stage and Production** run in parallel on the same server

## 🆘 Troubleshooting

See [docs/RUNBOOK.md](docs/RUNBOOK.md) for troubleshooting procedures.




