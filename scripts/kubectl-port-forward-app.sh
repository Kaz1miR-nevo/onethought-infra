#!/bin/bash
# =============================================================================
# Application Port Forward Script
# =============================================================================
# Opens a port forward to access the OneThought app locally
# Use this to test the deployment before exposing via DNS
# Usage: ./kubectl-port-forward-app.sh [port]
# =============================================================================

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NAMESPACE="onethought"
SERVICE="onethought-frontend"
LOCAL_PORT="${1:-3000}"
REMOTE_PORT="3000"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   OneThought App Port Forward              ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Check if service exists
if ! kubectl get svc "$SERVICE" -n "$NAMESPACE" &> /dev/null; then
    echo -e "${YELLOW}Service $SERVICE not found in namespace $NAMESPACE${NC}"
    echo ""
    echo "Available services:"
    kubectl get svc -n "$NAMESPACE"
    exit 1
fi

echo -e "${GREEN}Starting port forward...${NC}"
echo ""
echo -e "Access the application at: ${BLUE}http://localhost:$LOCAL_PORT${NC}"
echo ""
echo -e "${YELLOW}Note: This bypasses the ALB/Ingress and connects directly to the service.${NC}"
echo -e "Use this for testing before DNS is configured."
echo ""
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward svc/$SERVICE $LOCAL_PORT:$REMOTE_PORT -n $NAMESPACE

