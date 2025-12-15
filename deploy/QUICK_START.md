# Quick Start - DigitalOcean VPS Deployment

## 📋 One-Day Setup Checklist

### Step 1: Create DigitalOcean Droplet
- [ ] Create Droplet: 2 vCPU / 4 GB RAM / Ubuntu 22.04
- [ ] Note the IP address
- [ ] Add SSH key or set password

### Step 2: Configure DNS
- [ ] Point `domain.com` A record to VPS IP
- [ ] Point `stage.domain.com` A record to VPS IP
- [ ] Wait for DNS propagation (check with `dig domain.com`)

### Step 3: Initial Server Setup
```bash
ssh root@<VPS_IP>
cd /opt
git clone https://github.com/Kaz1miR-nevo/onethought-infra.git
git clone https://github.com/Kaz1miR-nevo/onethought-api.git
git clone https://github.com/Kaz1miR-nevo/onepost.git OneThought
cd onethought-infra/deploy
chmod +x scripts/*.sh
```

### Step 4: Run Bootstrap Scripts
```bash
./scripts/00_server_bootstrap.sh
./scripts/01_install_docker.sh
./scripts/02_configure_firewall.sh
./scripts/03_setup_nginx.sh
./scripts/04_setup_https_certbot.sh  # Will prompt for domains and email
```

### Step 5: Configure Environment Variables
```bash
cd env
cp stage.api.env.example stage.api.env
cp stage.web.env.example stage.web.env
cp prod.api.env.example prod.api.env
cp prod.web.env.example prod.web.env

# Edit each file and fill in your secrets
nano stage.api.env
nano stage.web.env
nano prod.api.env
nano prod.web.env
```

**Required values:**
- Supabase URLs and keys (from Supabase dashboard)
- JWT secrets (generate with `openssl rand -base64 32`)
- Site URLs

### Step 6: Deploy Applications
```bash
cd ..
./scripts/05_deploy_stage.sh
./scripts/06_deploy_prod.sh
```

### Step 7: Verify Deployment
```bash
./scripts/07_healthcheck.sh

# Test endpoints
curl https://stage.domain.com/api/health
curl https://domain.com/api/health
```

## ✅ Verification Checklist

- [ ] Stage domain loads: https://stage.domain.com
- [ ] Production domain loads: https://domain.com
- [ ] Health endpoints return 200
- [ ] SSL certificates are valid (green lock in browser)
- [ ] Containers are running: `docker ps`
- [ ] No errors in logs: `docker compose -p onethought_stage -f docker-compose.stage.yml logs`

## 📚 Next Steps

- Read [DEPLOY_DO_VPS.md](docs/DEPLOY_DO_VPS.md) for detailed documentation
- Read [RUNBOOK.md](docs/RUNBOOK.md) for operational procedures
- Read [SECRETS_AND_ENV.md](docs/SECRETS_AND_ENV.md) for environment variables guide

## 🆘 Troubleshooting

If something goes wrong:
1. Check logs: `docker compose -p onethought_stage -f docker-compose.stage.yml logs`
2. Check health: `./scripts/07_healthcheck.sh`
3. Review [RUNBOOK.md](docs/RUNBOOK.md) for common issues

