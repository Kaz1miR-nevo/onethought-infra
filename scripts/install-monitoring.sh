#!/bin/bash
# =============================================================================
# Install Monitoring Stack Script
# =============================================================================
# Installs Prometheus, Grafana, Loki, and Promtail
# Usage: ./install-monitoring.sh [stage|prod]
# =============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

ENVIRONMENT="${1:-stage}"
NAMESPACE="monitoring"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   Installing Monitoring Stack              ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""
echo "Environment: $ENVIRONMENT"
echo ""

# Add Helm repos
echo -e "${BLUE}Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
echo -e "${GREEN}[✓] Helm repos updated${NC}"

# Create namespace
echo ""
echo -e "${BLUE}Creating monitoring namespace...${NC}"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
echo -e "${GREEN}[✓] Namespace created${NC}"

# Install External Secrets Operator (if not installed)
echo ""
echo -e "${BLUE}Checking External Secrets Operator...${NC}"
if ! helm list -n external-secrets | grep -q "external-secrets"; then
    echo "Installing External Secrets Operator..."
    helm repo add external-secrets https://charts.external-secrets.io
    helm install external-secrets external-secrets/external-secrets \
        -n external-secrets \
        --create-namespace \
        --wait
    echo -e "${GREEN}[✓] External Secrets Operator installed${NC}"
else
    echo -e "${GREEN}[✓] External Secrets Operator already installed${NC}"
fi

# Install Prometheus stack
echo ""
echo -e "${BLUE}Installing Prometheus stack...${NC}"
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    -n "$NAMESPACE" \
    --wait \
    --timeout 10m

echo -e "${GREEN}[✓] Prometheus stack installed${NC}"

# Install Loki
echo ""
echo -e "${BLUE}Installing Loki...${NC}"
helm upgrade --install loki grafana/loki \
    -n "$NAMESPACE" \
    --wait \
    --timeout 10m

echo -e "${GREEN}[✓] Loki installed${NC}"

# Install Promtail
echo ""
echo -e "${BLUE}Installing Promtail...${NC}"
helm upgrade --install promtail grafana/promtail \
    -n "$NAMESPACE" \
    --set "config.clients[0].url=http://loki-gateway/loki/api/v1/push" \
    --wait

echo -e "${GREEN}[✓] Promtail installed${NC}"

# Apply custom dashboards
echo ""
echo -e "${BLUE}Applying custom dashboards...${NC}"
kubectl apply -f ../k8s/monitoring/grafana-dashboard-onethought.yaml
echo -e "${GREEN}[✓] Dashboards applied${NC}"

# Show access info
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   Monitoring Stack Installed!              ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo "To access Grafana:"
echo "  ./kubectl-port-forward-grafana.sh"
echo ""
echo "Then open: http://localhost:3000"
echo ""
echo "Default credentials:"
echo "  Username: admin"
echo "  Password: prom-operator"
echo ""

