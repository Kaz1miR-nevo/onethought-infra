#!/bin/bash
# =============================================================================
# Server Bootstrap Script
# =============================================================================
# Initial server setup for DigitalOcean VPS
# Run this FIRST on a fresh Ubuntu 22.04 droplet
# =============================================================================

set -euo pipefail

echo "🚀 Starting OneThought server bootstrap..."

# Update system
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install essential tools
echo "📦 Installing essential tools..."
sudo apt-get install -y \
    curl \
    wget \
    git \
    ufw \
    fail2ban \
    unattended-upgrades \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Configure automatic security updates
echo "🔒 Configuring automatic security updates..."
sudo dpkg-reconfigure -f noninteractive unattended-upgrades

# Create deployment user (optional, for security)
echo "👤 Creating deployment user..."
if ! id "onethought" &>/dev/null; then
    sudo useradd -m -s /bin/bash onethought
    echo "✅ User 'onethought' created"
    echo "⚠️  Remember to add SSH keys for 'onethought' user if needed"
else
    echo "ℹ️  User 'onethought' already exists"
fi

# Create deployment directory
echo "📁 Creating deployment directory..."
sudo mkdir -p /opt/onethought
sudo chown $USER:$USER /opt/onethought

echo "✅ Server bootstrap complete!"
echo ""
echo "Next steps:"
echo "1. Run: ./01_install_docker.sh"
echo "2. Run: ./02_configure_firewall.sh"
echo "3. Run: ./03_setup_nginx.sh"
echo "4. Run: ./04_setup_https_certbot.sh"
echo "5. Copy env files and run deploy scripts"




