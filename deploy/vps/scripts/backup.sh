#!/bin/bash
# =============================================================================
# OneThought VPS Backup Script
# =============================================================================
# Створює резервні копії логів та конфігурацій
# Рекомендується запускати через cron щодня
# =============================================================================

set -euo pipefail

# Конфігурація
BACKUP_DIR="/opt/onethought/backups"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Створюємо директорію для backup
mkdir -p "${BACKUP_DIR}"

echo "=========================================="
echo "OneThought Backup Script"
echo "=========================================="
echo "Дата: $(date)"
echo ""

# Backup nginx конфігурації
echo "[1/4] Backup nginx конфігурації..."
tar -czf "${BACKUP_DIR}/nginx_config_${DATE}.tar.gz" \
    /etc/nginx/sites-available/onethought.conf \
    /etc/nginx/nginx.conf 2>/dev/null || true

# Backup docker-compose та env файли
echo "[2/4] Backup конфігурацій застосунку..."
tar -czf "${BACKUP_DIR}/app_config_${DATE}.tar.gz" \
    /opt/onethought/app/docker-compose.vps.yml \
    /opt/onethought/app/.env.production 2>/dev/null || true

# Backup логів (останні 24 години)
echo "[3/4] Backup логів..."
tar -czf "${BACKUP_DIR}/logs_${DATE}.tar.gz" \
    /var/log/nginx/onethought-*.log \
    /opt/onethought/logs/*.log 2>/dev/null || true

# Видалення старих backup (старіше ніж RETENTION_DAYS)
echo "[4/4] Очищення старих backup..."
find "${BACKUP_DIR}" -type f -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete

echo ""
echo "Backup завершено!"
echo "Розташування: ${BACKUP_DIR}"
echo "Розмір backup директорії:"
du -sh "${BACKUP_DIR}"



