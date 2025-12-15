# DigitalOcean VPS Deployment Guide

## 📋 Overview

This guide covers deploying OneThought on a single DigitalOcean VPS (Droplet) with:
- **2 vCPU / 4 GB RAM** (Basic Droplet, ~$24/month)
- **Ubuntu 22.04 LTS**
- **Docker + Docker Compose** for containerization
- **Nginx** as reverse proxy
- **Let's Encrypt** for HTTPS
- **Redis** for caching and rate limiting
- **Two environments**: Stage and Production running in parallel

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    DigitalOcean VPS                           │
│                  (2 vCPU / 4 GB RAM)                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              Nginx (Port 80, 443)                  │    │
│  │  - stage.domain.com → stage containers              │    │
│  │  - domain.com → prod containers                    │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐                       │
│  │   STAGE      │  │   PRODUCTION  │                       │
│  ├──────────────┤  ├──────────────┤                       │
│  │ Web:3000     │  │ Web:3003     │                       │
│  │ API:3001     │  │ API:3002     │                       │
│  │ Redis:6379  │  │ Redis:6379   │                       │
│  │ (DB 0)      │  │ (DB 1)      │                       │
│  └──────────────┘  └──────────────┘                       │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start (One-Day Setup)

### Prerequisites

- DigitalOcean account
- Domain name with DNS access
- SSH access to the VPS

### Step 1: Create Droplet

1. Go to DigitalOcean → Create → Droplets
2. Choose:
   - **Image**: Ubuntu 22.04 LTS
   - **Plan**: Basic ($24/mo: 2 vCPU, 4 GB RAM)
   - **Region**: Choose closest to your users
   - **Authentication**: SSH keys (recommended) or password
3. Create droplet and note the IP address

### Step 2: DNS Configuration

Point your domains to the VPS IP:

```
Type    Name    Value           TTL
A       @       <VPS_IP>        3600
A       stage   <VPS_IP>        3600
```

Wait for DNS propagation (5-60 minutes). Verify with:
```bash
dig stage.domain.com
dig domain.com
```

### Step 3: Initial Server Setup

SSH into your VPS:
```bash
ssh root@<VPS_IP>
```

Clone all three repositories:
```bash
cd /opt
git clone https://github.com/Kaz1miR-nevo/onethought-infra.git
git clone https://github.com/Kaz1miR-nevo/onethought-api.git
git clone https://github.com/Kaz1miR-nevo/onepost.git OneThought
cd onethought-infra/deploy
```

### Step 4: Run Bootstrap Scripts

Run scripts in order:

```bash
# 1. Initial server setup
chmod +x scripts/*.sh
./scripts/00_server_bootstrap.sh

# 2. Install Docker
./scripts/01_install_docker.sh

# 3. Configure firewall
./scripts/02_configure_firewall.sh

# 4. Setup Nginx
./scripts/03_setup_nginx.sh

# 5. Setup HTTPS (will prompt for domains and email)
./scripts/04_setup_https_certbot.sh
```

### Step 5: Configure Environment Variables

Create environment files from examples:

```bash
cd /opt/onethought-infra/deploy/env

# Stage
cp stage.api.env.example stage.api.env
cp stage.web.env.example stage.web.env
nano stage.api.env  # Fill in your values
nano stage.web.env  # Fill in your values

# Production
cp prod.api.env.example prod.api.env
cp prod.web.env.example prod.web.env
nano prod.api.env  # Fill in your values
nano prod.web.env  # Fill in your values
```

**⚠️ IMPORTANT**: Never commit `.env` files to git!

### Step 6: Deploy Applications

```bash
cd /opt/onethought-infra/deploy

# Deploy Stage
./scripts/05_deploy_stage.sh

# Deploy Production
./scripts/06_deploy_prod.sh
```

### Step 7: Verify Deployment

```bash
# Run health checks
./scripts/07_healthcheck.sh

# Check containers
docker compose -p onethought_stage -f docker-compose.stage.yml ps
docker compose -p onethought_prod -f docker-compose.prod.yml ps

# Test endpoints
curl https://stage.domain.com/api/health
curl https://domain.com/api/health
```

## 📁 Directory Structure

```
/opt/onethought-infra/deploy/
├── docker-compose.stage.yml    # Stage environment
├── docker-compose.prod.yml      # Production environment
├── env/
│   ├── stage.api.env            # Stage API secrets (create from .example)
│   ├── stage.web.env            # Stage Web secrets (create from .example)
│   ├── prod.api.env             # Prod API secrets (create from .example)
│   └── prod.web.env             # Prod Web secrets (create from .example)
├── nginx/
│   ├── stage.conf               # Stage Nginx config
│   ├── prod.conf                # Prod Nginx config
│   └── snippets/                # Shared Nginx snippets
├── redis/
│   └── redis.conf               # Redis configuration
└── scripts/
    ├── 00_server_bootstrap.sh   # Initial setup
    ├── 01_install_docker.sh     # Docker installation
    ├── 02_configure_firewall.sh # UFW configuration
    ├── 03_setup_nginx.sh        # Nginx setup
    ├── 04_setup_https_certbot.sh # SSL certificates
    ├── 05_deploy_stage.sh       # Deploy stage
    ├── 06_deploy_prod.sh        # Deploy production
    ├── 07_healthcheck.sh        # Health checks
    └── 08_rollback.sh           # Rollback script
```

## 🔧 Port Allocation

| Service | Stage | Production |
|---------|-------|------------|
| Web     | 3000  | 3003       |
| API     | 3001  | 3002       |
| Redis   | Internal only (no public port) |

Nginx listens on ports 80 (HTTP) and 443 (HTTPS) and routes to the appropriate containers.

## 🔐 Security

### Firewall (UFW)
- **Allowed**: SSH (22), HTTP (80), HTTPS (443)
- **Blocked**: Everything else
- Redis is **NOT** exposed to the internet (internal Docker network only)

### SSL/TLS
- Certificates managed by Let's Encrypt via Certbot
- Auto-renewal configured via systemd timer
- HTTP automatically redirects to HTTPS

### Environment Files
- Stored in `/opt/onethought-infra/deploy/env/`
- **Never commit to git**
- Restrict permissions: `chmod 600 env/*.env`

### SSH Hardening (Recommended)
```bash
# Disable password authentication (use SSH keys only)
sudo nano /etc/ssh/sshd_config
# Set: PasswordAuthentication no
sudo systemctl restart sshd
```

## 🔄 Maintenance

### View Logs
```bash
# Stage
docker compose -p onethought_stage -f docker-compose.stage.yml logs -f

# Production
docker compose -p onethought_prod -f docker-compose.prod.yml logs -f

# Nginx
sudo tail -f /var/log/nginx/stage.access.log
sudo tail -f /var/log/nginx/prod.access.log
```

### Update Applications
```bash
cd /opt/onethought-infra/deploy

# Pull latest code (in respective repos)
cd ../../OneThought && git pull
cd ../onethought-api && git pull

# Rebuild and redeploy
cd ../onethought-infra/deploy
./scripts/05_deploy_stage.sh  # Stage
./scripts/06_deploy_prod.sh   # Production
```

### Rollback
```bash
./scripts/08_rollback.sh
```

### Restart Services
```bash
# Stage
docker compose -p onethought_stage -f docker-compose.stage.yml restart

# Production
docker compose -p onethought_prod -f docker-compose.prod.yml restart
```

## 📊 Monitoring

### Health Checks
```bash
./scripts/07_healthcheck.sh
```

### Resource Usage
```bash
# Container stats
docker stats

# Disk usage
df -h

# Memory
free -h
```

## 🐛 Troubleshooting

### Containers won't start
```bash
# Check logs
docker compose -p onethought_stage -f docker-compose.stage.yml logs

# Check environment files
cat env/stage.api.env  # Verify all required vars are set
```

### Nginx errors
```bash
# Test configuration
sudo nginx -t

# Check error logs
sudo tail -f /var/log/nginx/error.log
```

### SSL certificate issues
```bash
# Renew manually
sudo certbot renew --dry-run

# Check certificate expiry
sudo certbot certificates
```

### Redis connection issues
```bash
# Check Redis container
docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli ping

# Check Redis logs
docker compose -p onethought_stage -f docker-compose.stage.yml logs redis
```

## 💰 Cost Estimate

- **Droplet**: $24/month (2 vCPU, 4 GB RAM)
- **Backups** (optional): +20% = $4.80/month
- **Total**: ~$29/month

## 🚀 Future Migration to AWS/K8s

This setup is designed to be easily migrated to AWS EKS when needed. See [MIGRATION_FUTURE_AWS_K8S.md](MIGRATION_FUTURE_AWS_K8S.md) for details.

## 📚 Additional Documentation

- [RUNBOOK.md](RUNBOOK.md) - Operational runbook
- [SECRETS_AND_ENV.md](SECRETS_AND_ENV.md) - Environment variables guide
- [REDIS_USAGE_GUIDE.md](REDIS_USAGE_GUIDE.md) - Redis usage and configuration

