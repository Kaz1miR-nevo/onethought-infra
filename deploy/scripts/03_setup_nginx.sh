#!/bin/bash
# =============================================================================
# Nginx Setup Script
# =============================================================================
# Installs and configures Nginx as reverse proxy
# Idempotent: safe to run multiple times
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

echo "🌐 Setting up Nginx..."

# Install Nginx
if ! command -v nginx &> /dev/null; then
    echo "📦 Installing Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
else
    echo "✅ Nginx is already installed"
fi

# Create snippets directory
echo "📁 Creating Nginx snippets directory..."
sudo mkdir -p /etc/nginx/snippets

# Copy snippet files
echo "📋 Copying Nginx snippets..."
sudo cp "$DEPLOY_DIR/nginx/snippets/security-headers.conf" /etc/nginx/snippets/
sudo cp "$DEPLOY_DIR/nginx/snippets/gzip.conf" /etc/nginx/snippets/
sudo cp "$DEPLOY_DIR/nginx/snippets/rate-limit.conf" /etc/nginx/snippets/
sudo cp "$DEPLOY_DIR/nginx/snippets/websocket.conf" /etc/nginx/snippets/

# Backup existing nginx.conf
if [ ! -f /etc/nginx/nginx.conf.backup ]; then
    echo "💾 Backing up nginx.conf..."
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup
fi

# Add rate limiting zones and websocket support to nginx.conf (if not already present)
if ! grep -q "rate-limit.conf" /etc/nginx/nginx.conf; then
    echo "📋 Adding rate limiting zones to nginx.conf..."
    sudo sed -i '/^http {/a\    # Rate limiting zones\n    include /etc/nginx/snippets/rate-limit.conf;' /etc/nginx/nginx.conf
fi

if ! grep -q "websocket.conf" /etc/nginx/nginx.conf; then
    echo "📋 Adding WebSocket support to nginx.conf..."
    sudo sed -i '/^http {/a\    # WebSocket support\n    include /etc/nginx/snippets/websocket.conf;' /etc/nginx/nginx.conf
fi

# Copy server configurations (but don't enable yet - wait for SSL)
echo "📋 Copying server configurations..."
sudo cp "$DEPLOY_DIR/nginx/stage.conf" /etc/nginx/sites-available/stage.onethought
sudo cp "$DEPLOY_DIR/nginx/prod.conf" /etc/nginx/sites-available/onethought

# Remove default site
if [ -L /etc/nginx/sites-enabled/default ]; then
    echo "🗑️  Removing default Nginx site..."
    sudo rm /etc/nginx/sites-enabled/default
fi

# Test Nginx configuration
echo "🧪 Testing Nginx configuration..."
sudo nginx -t

# Start and enable Nginx
echo "🚀 Starting Nginx..."
sudo systemctl start nginx
sudo systemctl enable nginx

echo "✅ Nginx setup complete!"
echo ""
echo "⚠️  Note: Server blocks are not enabled yet."
echo "   They will be enabled after SSL certificates are obtained (step 04)"

