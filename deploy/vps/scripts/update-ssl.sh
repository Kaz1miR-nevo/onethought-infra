#!/bin/bash
# =============================================================================
# OneThought SSL Certificate Update Script
# =============================================================================
# Оновлює SSL сертифікати Let's Encrypt та перезавантажує nginx
# =============================================================================

set -euo pipefail

DOMAIN="birka.one"
EMAIL="your-email@example.com"  # ЗМІНІТЬ НА ВАШУ ПОШТУ

echo "=========================================="
echo "OneThought SSL Certificate Update"
echo "=========================================="

# Перевірка чи встановлено certbot
if ! command -v certbot &> /dev/null; then
    echo "Помилка: certbot не встановлено"
    exit 1
fi

# Отримання/оновлення сертифікату
echo "Оновлення SSL сертифікату для ${DOMAIN}..."
certbot renew --nginx --quiet --no-self-upgrade

# Перезавантаження nginx
echo "Перезавантаження nginx..."
systemctl reload nginx

echo "SSL сертифікат оновлено успішно!"

# Перевірка статусу
echo ""
echo "Перевірка сертифікату:"
openssl s_client -connect ${DOMAIN}:443 -servername ${DOMAIN} < /dev/null 2>/dev/null | \
    openssl x509 -noout -dates

