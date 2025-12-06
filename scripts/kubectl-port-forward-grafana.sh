#!/bin/bash
# =============================================================================
# Grafana Port Forward Script
# =============================================================================
# Opens a port forward to access Grafana locally
# Usage: ./kubectl-port-forward-grafana.sh
# =============================================================================

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
NC='\033[0m'

NAMESPACE="monitoring"
SERVICE="prometheus-grafana"
LOCAL_PORT="${1:-3000}"
REMOTE_PORT="80"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   Grafana Port Forward                     ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Check if service exists
if ! kubectl get svc "$SERVICE" -n "$NAMESPACE" &> /dev/null; then
    echo "Error: Service $SERVICE not found in namespace $NAMESPACE"
    echo "Make sure the monitoring stack is installed."
    exit 1
fi

echo -e "${GREEN}Starting port forward...${NC}"
echo ""
echo -e "Access Grafana at: ${BLUE}http://localhost:$LOCAL_PORT${NC}"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: (set during installation)"
echo ""
echo "Press Ctrl+C to stop"
echo ""

kubectl port-forward svc/$SERVICE $LOCAL_PORT:$REMOTE_PORT -n $NAMESPACE

