#!/bin/bash
# =============================================================================
# HTTPS Setup with Certbot
# =============================================================================
# Installs Certbot and obtains SSL certificates for stage and prod domains
# Idempotent: safe to run multiple times (will renew if needed)
# =============================================================================

set -euo pipefail

echo "🔒 Setting up HTTPS with Let's Encrypt..."

# Install Certbot
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing Certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot python3-certbot-nginx
else
    echo "✅ Certbot is already installed"
fi

# Get domains from user or use defaults
read -p "Enter stage domain (default: stage.domain.com): " STAGE_DOMAIN
STAGE_DOMAIN=${STAGE_DOMAIN:-stage.domain.com}

read -p "Enter production domain (default: domain.com): " PROD_DOMAIN
PROD_DOMAIN=${PROD_DOMAIN:-domain.com}

read -p "Enter email for Let's Encrypt notifications: " EMAIL

# Note: domains will be updated after certificate issuance

# Create temporary HTTP-only configs for certificate issuance
echo "📋 Creating temporary HTTP configs for certificate issuance..."

# Stage: HTTP only (for initial cert)
sudo tee /etc/nginx/sites-available/stage.onethought.temp > /dev/null <<EOF
server {
    listen 80;
    server_name $STAGE_DOMAIN;
    location / {
        return 200 "Certificate issuance in progress";
        add_header Content-Type text/plain;
    }
}
EOF

# Prod: HTTP only (for initial cert)
sudo tee /etc/nginx/sites-available/onethought.temp > /dev/null <<EOF
server {
    listen 80;
    server_name $PROD_DOMAIN;
    location / {
        return 200 "Certificate issuance in progress";
        add_header Content-Type text/plain;
    }
}
EOF

# Enable temp configs
sudo ln -sf /etc/nginx/sites-available/stage.onethought.temp /etc/nginx/sites-enabled/stage.onethought.temp
sudo ln -sf /etc/nginx/sites-available/onethought.temp /etc/nginx/sites-enabled/onethought.temp
sudo nginx -t && sudo systemctl reload nginx

# Obtain certificates
echo "🔐 Obtaining SSL certificates..."

# Stage certificate
echo "📜 Obtaining certificate for $STAGE_DOMAIN..."
sudo certbot certonly --nginx \
    -d "$STAGE_DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive \
    --keep-until-expiring || echo "⚠️  Certificate for $STAGE_DOMAIN may already exist"

# Prod certificate
echo "📜 Obtaining certificate for $PROD_DOMAIN..."
sudo certbot certonly --nginx \
    -d "$PROD_DOMAIN" \
    --email "$EMAIL" \
    --agree-tos \
    --non-interactive \
    --keep-until-expiring || echo "⚠️  Certificate for $PROD_DOMAIN may already exist"

# Remove temp configs
sudo rm -f /etc/nginx/sites-enabled/stage.onethought.temp
sudo rm -f /etc/nginx/sites-enabled/onethought.temp

# Update nginx configs with actual certificate paths
sudo sed -i "s/stage.domain.com/$STAGE_DOMAIN/g" /etc/nginx/sites-available/stage.onethought
sudo sed -i "s/domain.com/$PROD_DOMAIN/g" /etc/nginx/sites-available/onethought

# Enable server blocks
echo "📋 Enabling server blocks..."
sudo ln -sf /etc/nginx/sites-available/stage.onethought /etc/nginx/sites-enabled/
sudo ln -sf /etc/nginx/sites-available/onethought /etc/nginx/sites-enabled/

# Test and reload
sudo nginx -t
sudo systemctl reload nginx

# Setup auto-renewal
echo "🔄 Setting up automatic certificate renewal..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

echo "✅ HTTPS setup complete!"
echo ""
echo "📋 Certificates obtained for:"
echo "   - $STAGE_DOMAIN"
echo "   - $PROD_DOMAIN"
echo ""
echo "🔄 Auto-renewal is enabled via systemd timer"

