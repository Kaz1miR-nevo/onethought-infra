#!/bin/bash
# =============================================================================
# Helm Rollback Script
# =============================================================================
# Rolls back to a previous deployment
# Usage: ./rollback.sh [revision]
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

NAMESPACE="onethought"
RELEASE_NAME="onethought"
REVISION="${1:-}"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   Helm Rollback                            ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Show history
echo -e "${BLUE}Deployment history:${NC}"
helm history "$RELEASE_NAME" -n "$NAMESPACE"
echo ""

# If no revision specified, show prompt
if [ -z "$REVISION" ]; then
    echo -e "${YELLOW}No revision specified.${NC}"
    read -p "Enter revision number to rollback to (or press Enter for previous): " REVISION
    
    if [ -z "$REVISION" ]; then
        # Get previous revision
        CURRENT=$(helm history "$RELEASE_NAME" -n "$NAMESPACE" --max 1 -o json | jq -r '.[0].revision')
        REVISION=$((CURRENT - 1))
        echo "Rolling back to revision $REVISION"
    fi
fi

# Confirm rollback
echo ""
echo -e "${YELLOW}You are about to rollback to revision $REVISION${NC}"
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled."
    exit 0
fi

# Perform rollback
echo ""
echo -e "${BLUE}Rolling back to revision $REVISION...${NC}"
helm rollback "$RELEASE_NAME" "$REVISION" -n "$NAMESPACE" --wait

echo ""
echo -e "${GREEN}Rollback complete!${NC}"
echo ""

# Show current status
echo -e "${BLUE}Current deployment status:${NC}"
kubectl get pods -n "$NAMESPACE"

