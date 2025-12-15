#!/bin/bash
# =============================================================================
# Deploy Production Environment
# =============================================================================
# Builds and deploys production environment using Docker Compose
# Idempotent: safe to run multiple times (will rebuild if needed)
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

echo "🚀 Deploying Production environment..."

# Safety check
read -p "⚠️  Are you sure you want to deploy to PRODUCTION? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

cd "$DEPLOY_DIR"

# Check if repositories are cloned
if [ ! -d "/opt/onethought-api" ]; then
    echo "❌ Error: API repository not found at /opt/onethought-api"
    echo "   Please clone: git clone https://github.com/Kaz1miR-nevo/onethought-api.git /opt/onethought-api"
    exit 1
fi

if [ ! -d "/opt/OneThought" ]; then
    echo "❌ Error: Web repository not found at /opt/OneThought"
    echo "   Please clone: git clone https://github.com/Kaz1miR-nevo/onepost.git /opt/OneThought"
    exit 1
fi

# Check if env files exist
if [ ! -f "env/prod.api.env" ] || [ ! -f "env/prod.web.env" ]; then
    echo "❌ Error: Environment files not found!"
    echo "   Please create:"
    echo "   - env/prod.api.env (from env/prod.api.env.example)"
    echo "   - env/prod.web.env (from env/prod.web.env.example)"
    exit 1
fi

# Build and start containers
echo "🔨 Building and starting containers..."
docker compose -p onethought_prod -f docker-compose.prod.yml build --no-cache

echo "🚀 Starting containers..."
docker compose -p onethought_prod -f docker-compose.prod.yml up -d

# Wait for health checks
echo "⏳ Waiting for services to be healthy..."
sleep 10

# Check health
echo "🏥 Checking service health..."
if curl -f http://localhost:3002/health > /dev/null 2>&1; then
    echo "✅ API is healthy"
else
    echo "⚠️  API health check failed (may still be starting)"
fi

if curl -f http://localhost:3003/api/health > /dev/null 2>&1; then
    echo "✅ Web is healthy"
else
    echo "⚠️  Web health check failed (may still be starting)"
fi

# Show status
echo ""
echo "📊 Container status:"
docker compose -p onethought_prod -f docker-compose.prod.yml ps

echo ""
echo "✅ Production deployment complete!"
echo "   Web: http://localhost:3003"
echo "   API: http://localhost:3002"
echo ""
echo "📋 View logs: docker compose -p onethought_prod -f docker-compose.prod.yml logs -f"

