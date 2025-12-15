#!/bin/bash
# =============================================================================
# Health Check Script
# =============================================================================
# Verifies that all services are running and healthy
# =============================================================================

set -euo pipefail

echo "🏥 Running health checks..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed"
    exit 1
fi

# Check Stage services
echo ""
echo "📊 Stage Environment:"
if docker compose -p onethought_stage -f docker-compose.stage.yml ps | grep -q "Up"; then
    echo "✅ Stage containers are running"
    
    # Check API
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        echo "✅ Stage API: healthy"
    else
        echo "❌ Stage API: unhealthy"
    fi
    
    # Check Web
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "✅ Stage Web: healthy"
    else
        echo "❌ Stage Web: unhealthy"
    fi
else
    echo "⚠️  Stage containers are not running"
fi

# Check Prod services
echo ""
echo "📊 Production Environment:"
if docker compose -p onethought_prod -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo "✅ Prod containers are running"
    
    # Check API
    if curl -f http://localhost:3002/health > /dev/null 2>&1; then
        echo "✅ Prod API: healthy"
    else
        echo "❌ Prod API: unhealthy"
    fi
    
    # Check Web
    if curl -f http://localhost:3003/api/health > /dev/null 2>&1; then
        echo "✅ Prod Web: healthy"
    else
        echo "❌ Prod Web: unhealthy"
    fi
else
    echo "⚠️  Prod containers are not running"
fi

# Check Nginx
echo ""
echo "📊 Nginx:"
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running"
    if sudo nginx -t > /dev/null 2>&1; then
        echo "✅ Nginx configuration is valid"
    else
        echo "❌ Nginx configuration has errors"
    fi
else
    echo "❌ Nginx is not running"
fi

# Check SSL certificates
echo ""
echo "📊 SSL Certificates:"
if [ -d "/etc/letsencrypt/live" ]; then
    for domain_dir in /etc/letsencrypt/live/*/; do
        domain=$(basename "$domain_dir")
        if [ -f "$domain_dir/fullchain.pem" ]; then
            expiry=$(openssl x509 -enddate -noout -in "$domain_dir/fullchain.pem" | cut -d= -f2)
            echo "✅ $domain: valid until $expiry"
        fi
    done
else
    echo "⚠️  No SSL certificates found"
fi

echo ""
echo "✅ Health check complete!"

