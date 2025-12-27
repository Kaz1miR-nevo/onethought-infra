#!/bin/bash
# =============================================================================
# OneThought VPS Setup Script
# =============================================================================
# Цей скрипт налаштовує сервер HostIQ kVPS50 для OneThought
# Виконати після першого входу на сервер як root
# =============================================================================

set -euo pipefail

echo "=========================================="
echo "OneThought VPS Setup Script"
echo "=========================================="

# =============================================================================
# 1. Оновлення системи
# =============================================================================
echo "[1/10] Оновлення системи..."
dnf update -y
dnf upgrade -y

# =============================================================================
# 2. Встановлення базових пакетів
# =============================================================================
echo "[2/10] Встановлення базових пакетів..."
dnf install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    net-tools \
    bind-utils \
    yum-utils \
    epel-release \
    fail2ban \
    ufw \
    cronie \
    logrotate

# =============================================================================
# 3. Встановлення Docker та Docker Compose
# =============================================================================
echo "[3/10] Встановлення Docker..."
# Видаляємо старі версії (якщо є)
dnf remove -y docker docker-client docker-client-latest docker-common \
    docker-latest docker-latest-logrotate docker-logrotate docker-engine

# Додаємо Docker repository
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

# Встановлюємо Docker
dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Запускаємо Docker
systemctl start docker
systemctl enable docker

# Додаємо поточного користувача до групи docker
if [ -n "${SUDO_USER:-}" ]; then
    usermod -aG docker "$SUDO_USER"
elif [ -n "${USER:-}" ] && [ "$USER" != "root" ]; then
    usermod -aG docker "$USER"
fi

# Перевіряємо встановлення
docker --version
docker compose version

# =============================================================================
# 4. Налаштування firewall (firewalld)
# =============================================================================
echo "[4/10] Налаштування firewall..."
systemctl start firewalld
systemctl enable firewalld

# Дозволяємо SSH (обов'язково!)
firewall-cmd --permanent --add-service=ssh

# Дозволяємо HTTP та HTTPS
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https

# Перезавантажуємо firewall
firewall-cmd --reload

# Показуємо статус
firewall-cmd --list-all

# =============================================================================
# 5. Встановлення Nginx
# =============================================================================
echo "[5/10] Встановлення Nginx..."
dnf install -y nginx

# Запускаємо Nginx (поки що без конфігурації)
systemctl start nginx
systemctl enable nginx

# =============================================================================
# 6. Встановлення Certbot (Let's Encrypt)
# =============================================================================
echo "[6/10] Встановлення Certbot..."
dnf install -y certbot python3-certbot-nginx

# Створюємо директорію для ACME challenge
mkdir -p /var/www/certbot
chown -R nginx:nginx /var/www/certbot

# =============================================================================
# 7. Налаштування fail2ban
# =============================================================================
echo "[7/10] Налаштування fail2ban..."
systemctl start fail2ban
systemctl enable fail2ban

# Створюємо базову конфігурацію для SSH
cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[sshd]
enabled = true
port = ssh
logpath = /var/log/secure
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
EOF

systemctl restart fail2ban

# =============================================================================
# 8. Створення структури директорій
# =============================================================================
echo "[8/10] Створення структури директорій..."
mkdir -p /opt/onethought/{app,api,logs,backups,scripts}
mkdir -p /var/www/onethought

# Налаштування прав
chown -R "$(whoami):$(whoami)" /opt/onethought
chmod -R 755 /opt/onethought

# =============================================================================
# 9. Налаштування logrotate
# =============================================================================
echo "[9/10] Налаштування logrotate..."
cat > /etc/logrotate.d/onethought <<EOF
/var/log/nginx/onethought-*.log {
    daily
    rotate 14
    compress
    delaycompress
    missingok
    notifempty
    create 0640 nginx nginx
    sharedscripts
    postrotate
        systemctl reload nginx > /dev/null 2>&1 || true
    endscript
}

/opt/onethought/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 0644 root root
}
EOF

# =============================================================================
# 10. Налаштування swap (опціонально, якщо немає)
# =============================================================================
echo "[10/10] Перевірка swap..."
if ! swapon --show | grep -q .; then
    echo "Створення swap файлу (2GB)..."
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    
    # Налаштування swappiness
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
    sysctl -p
else
    echo "Swap вже налаштований"
fi

# =============================================================================
# Завершення
# =============================================================================
echo ""
echo "=========================================="
echo "Setup завершено успішно!"
echo "=========================================="
echo ""
echo "Наступні кроки:"
echo "1. Налаштуйте DNS записи для доменів"
echo "2. Клонуйте репозиторії:"
echo "   - git clone https://github.com/Kaz1miR-nevo/onethought-infra.git /opt/onethought-infra"
echo "   - git clone https://github.com/Kaz1miR-nevo/onethought-api.git /opt/onethought-api"
echo "   - git clone https://github.com/Kaz1miR-nevo/onepost.git /opt/OneThought"
echo "3. Скопіюйте nginx конфігурацію:"
echo "   cp /opt/onethought-infra/deploy/vps/nginx/onethought.conf /etc/nginx/sites-available/"
echo "4. Налаштуйте env файли в /opt/onethought-infra/deploy/env/"
echo "5. Запустіть скрипт deploy.sh для деплою"
echo ""
echo "Важливо: Перезавантажте сесію SSH або виконайте 'newgrp docker'"
echo "          для використання Docker без sudo"
echo ""



