#!/bin/bash
# =============================================================================
# Firewall Configuration Script
# =============================================================================
# Configures UFW (Uncomplicated Firewall) for OneThought
# Allows: SSH (22), HTTP (80), HTTPS (443)
# Blocks: Everything else
# Idempotent: safe to run multiple times
# =============================================================================

set -euo pipefail

echo "🔥 Configuring firewall (UFW)..."

# Enable UFW if not already enabled
if ! sudo ufw status | grep -q "Status: active"; then
    echo "📋 Setting default policies..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    
    echo "📋 Allowing SSH (port 22)..."
    sudo ufw allow 22/tcp comment 'SSH'
    
    echo "📋 Allowing HTTP (port 80)..."
    sudo ufw allow 80/tcp comment 'HTTP'
    
    echo "📋 Allowing HTTPS (port 443)..."
    sudo ufw allow 443/tcp comment 'HTTPS'
    
    echo "🔥 Enabling UFW..."
    sudo ufw --force enable
    
    echo "✅ Firewall configured and enabled"
else
    echo "✅ Firewall is already configured"
fi

# Show status
echo ""
echo "📊 Firewall status:"
sudo ufw status verbose

echo ""
echo "⚠️  IMPORTANT: Ensure SSH access is working before closing this session!"
echo "   If you lose SSH access, you can recover via DigitalOcean console"






