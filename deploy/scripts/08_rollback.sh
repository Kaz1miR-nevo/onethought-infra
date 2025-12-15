#!/bin/bash
# =============================================================================
# Rollback Script
# =============================================================================
# Rolls back to previous container images or stops services
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

echo "🔄 Rollback script"
echo ""
echo "Select environment to rollback:"
echo "1) Stage"
echo "2) Production"
echo "3) Both"
read -p "Choice (1-3): " CHOICE

cd "$DEPLOY_DIR"

case $CHOICE in
    1)
        echo "🔄 Rolling back Stage..."
        docker compose -p onethought_stage -f docker-compose.stage.yml down
        echo "✅ Stage rolled back (containers stopped)"
        echo "   To restart: ./05_deploy_stage.sh"
        ;;
    2)
        read -p "⚠️  Rollback PRODUCTION? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            echo "🔄 Rolling back Production..."
            docker compose -p onethought_prod -f docker-compose.prod.yml down
            echo "✅ Production rolled back (containers stopped)"
            echo "   To restart: ./06_deploy_prod.sh"
        else
            echo "❌ Rollback cancelled"
        fi
        ;;
    3)
        read -p "⚠️  Rollback BOTH environments? (yes/no): " CONFIRM
        if [ "$CONFIRM" = "yes" ]; then
            echo "🔄 Rolling back both environments..."
            docker compose -p onethought_stage -f docker-compose.stage.yml down
            docker compose -p onethought_prod -f docker-compose.prod.yml down
            echo "✅ Both environments rolled back"
        else
            echo "❌ Rollback cancelled"
        fi
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "💡 To restore from backup images, use:"
echo "   docker compose -p onethought_<env> -f docker-compose.<env>.yml pull"
echo "   docker compose -p onethought_<env> -f docker-compose.<env>.yml up -d"

