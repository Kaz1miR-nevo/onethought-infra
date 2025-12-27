# OneThought VPS Runbook

## 🚨 Emergency Procedures

### Service Down

1. **Check container status**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml ps
   docker compose -p onethought_prod -f docker-compose.prod.yml ps
   ```

2. **Check logs**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml logs --tail=100
   ```

3. **Restart service**
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml restart <service>
   ```

4. **If restart fails, redeploy**
   ```bash
   cd /opt/onethought-infra/deploy
   ./scripts/05_deploy_stage.sh
   ```

### High Memory Usage

1. **Check memory**
   ```bash
   free -h
   docker stats --no-stream
   ```

2. **Restart containers** (clears memory leaks)
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml restart
   ```

3. **Clear Redis cache** (if needed)
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli FLUSHDB
   ```

### SSL Certificate Expiring

1. **Check expiry**
   ```bash
   sudo certbot certificates
   ```

2. **Renew manually**
   ```bash
   sudo certbot renew
   sudo systemctl reload nginx
   ```

### Database Connection Issues

1. **Check Supabase status**
   - Visit: https://status.supabase.com

2. **Verify credentials**
   ```bash
   cat /opt/onethought-infra/deploy/env/stage.api.env | grep SUPABASE
   ```

3. **Test connection** (from API container)
   ```bash
   docker compose -p onethought_stage -f docker-compose.stage.yml exec api node -e "console.log(process.env.SUPABASE_URL)"
   ```

## 📋 Daily Operations

### Morning Checklist

- [ ] Check health endpoints
  ```bash
  curl https://stage.domain.com/api/health
  curl https://domain.com/api/health
  ```
- [ ] Review error logs
  ```bash
  sudo tail -100 /var/log/nginx/stage.error.log
  docker compose -p onethought_stage -f docker-compose.stage.yml logs --tail=50
  ```
- [ ] Check disk space
  ```bash
  df -h
  ```

### Weekly Maintenance

- [ ] Update system packages
  ```bash
  sudo apt-get update && sudo apt-get upgrade -y
  ```
- [ ] Clean Docker images
  ```bash
  docker system prune -a --volumes
  ```
- [ ] Review SSL certificates
  ```bash
  sudo certbot certificates
  ```
- [ ] Backup environment files
  ```bash
  tar -czf env-backup-$(date +%Y%m%d).tar.gz /opt/onethought-infra/deploy/env/
  ```

## 🔄 Deployment Procedures

### Deploy New Version

1. **Pull latest code**
   ```bash
   cd /opt/OneThought && git pull
   cd /opt/onethought-api && git pull
   ```

2. **Deploy to Stage first**
   ```bash
   cd /opt/onethought-infra/deploy
   ./scripts/05_deploy_stage.sh
   ```

3. **Test Stage**
   - Visit https://stage.domain.com
   - Run smoke tests
   - Check logs

4. **Deploy to Production** (if Stage is OK)
   ```bash
   ./scripts/06_deploy_prod.sh
   ```

### Rollback Procedure

1. **Stop current version**
   ```bash
   ./scripts/08_rollback.sh
   ```

2. **Redeploy previous version**
   ```bash
   # Checkout previous commit
   cd /opt/OneThought && git checkout <previous-commit>
   cd /opt/onethought-api && git checkout <previous-commit>
   
   # Redeploy
   cd /opt/onethought-infra/deploy
   ./scripts/05_deploy_stage.sh
   ./scripts/06_deploy_prod.sh
   ```

## 📊 Monitoring

### Health Endpoints

- Stage API: `https://stage.domain.com/api/health`
- Stage Web: `https://stage.domain.com/api/health`
- Prod API: `https://domain.com/api/health`
- Prod Web: `https://domain.com/api/health`

### Log Locations

- **Nginx**: `/var/log/nginx/`
- **Container logs**: `docker compose logs`
- **System logs**: `/var/log/syslog`

### Key Metrics to Monitor

- Container CPU/Memory usage
- Disk space (especially `/var/lib/docker`)
- SSL certificate expiry
- Nginx error rate
- API response times

## 🔧 Common Tasks

### View Real-time Logs
```bash
# Stage
docker compose -p onethought_stage -f docker-compose.stage.yml logs -f

# Production
docker compose -p onethought_prod -f docker-compose.prod.yml logs -f

# Specific service
docker compose -p onethought_stage -f docker-compose.stage.yml logs -f api
```

### Execute Commands in Containers
```bash
# Stage API
docker compose -p onethought_stage -f docker-compose.stage.yml exec api sh

# Redis CLI
docker compose -p onethought_stage -f docker-compose.stage.yml exec redis redis-cli
```

### Restart Services
```bash
# Restart all stage services
docker compose -p onethought_stage -f docker-compose.stage.yml restart

# Restart specific service
docker compose -p onethought_stage -f docker-compose.stage.yml restart api
```

### Update Nginx Configuration
```bash
# Edit config
sudo nano /etc/nginx/sites-available/stage.onethought

# Test
sudo nginx -t

# Reload
sudo systemctl reload nginx
```

## 🚨 Incident Response

### 1. Identify Issue
- Check health endpoints
- Review logs
- Check system resources

### 2. Contain Impact
- If production affected, consider rolling back
- If stage affected, fix before deploying to prod

### 3. Resolve
- Follow procedures above
- Document root cause

### 4. Post-Mortem
- Document what happened
- Update runbook if needed
- Implement preventive measures

## 📞 Escalation

If issues persist:
1. Check [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
2. Review application logs
3. Check Supabase status
4. Contact team lead if critical






