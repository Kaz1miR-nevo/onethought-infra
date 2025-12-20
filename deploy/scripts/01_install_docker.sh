#!/bin/bash
# =============================================================================
# Docker Installation Script
# =============================================================================
# Installs Docker and Docker Compose on Ubuntu 22.04
# Idempotent: safe to run multiple times
# =============================================================================

set -euo pipefail

echo "🐳 Installing Docker..."

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "✅ Docker is already installed"
    docker --version
    docker compose version
    exit 0
fi

# Install Docker
echo "📦 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

# Add current user to docker group (to run without sudo)
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Verify installation
echo "✅ Docker installed successfully"
docker --version
docker compose version

echo ""
echo "⚠️  IMPORTANT: You may need to log out and back in for group changes to take effect"
echo "   Or run: newgrp docker"




