#!/bin/bash
# =============================================================================
# OneThought Stage Deployment Script
# =============================================================================
# Deploys the application to the stage environment
# Usage: ./deploy-stage.sh [image-tag]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="stage"
CLUSTER_NAME="onethought-stage-eks"
REGION="eu-central-1"
NAMESPACE="onethought"
RELEASE_NAME="onethought"
CHART_PATH="../helm/onethought"
VALUES_FILE="../helm/onethought/values.stage.yaml"

# Get image tag from argument or use 'latest'
IMAGE_TAG="${1:-latest}"

# Print header
echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   OneThought Stage Deployment              ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Function to print status
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"

if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    exit 1
fi
print_status "AWS CLI installed"

if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed"
    exit 1
fi
print_status "kubectl installed"

if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed"
    exit 1
fi
print_status "Helm installed"

# Verify AWS authentication
echo ""
echo -e "${BLUE}Verifying AWS authentication...${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text 2>/dev/null || true)
if [ -z "$AWS_ACCOUNT_ID" ]; then
    print_error "Not authenticated to AWS. Please run 'aws configure' or set credentials"
    exit 1
fi
print_status "Authenticated as account: $AWS_ACCOUNT_ID"

# Update kubeconfig
echo ""
echo -e "${BLUE}Configuring kubectl for cluster: $CLUSTER_NAME...${NC}"
aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" --alias "$CLUSTER_NAME"
print_status "kubectl configured"

# Verify cluster connectivity
echo ""
echo -e "${BLUE}Verifying cluster connectivity...${NC}"
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to cluster"
    exit 1
fi
print_status "Connected to cluster"

# Check cluster health
echo ""
echo -e "${BLUE}Checking cluster health...${NC}"
./check-cluster-health.sh || {
    print_warning "Cluster health check returned warnings"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
}

# Create namespace if it doesn't exist
echo ""
echo -e "${BLUE}Ensuring namespace exists...${NC}"
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
print_status "Namespace $NAMESPACE ready"

# Get ECR repository URL
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/onethought-stage-frontend"

# Deploy with Helm
echo ""
echo -e "${BLUE}Deploying with Helm...${NC}"
echo "  Release: $RELEASE_NAME"
echo "  Namespace: $NAMESPACE"
echo "  Image: $ECR_REPO:$IMAGE_TAG"
echo ""

helm upgrade --install "$RELEASE_NAME" "$CHART_PATH" \
    --namespace "$NAMESPACE" \
    --values "$VALUES_FILE" \
    --set frontend.image.repository="$ECR_REPO" \
    --set frontend.image.tag="$IMAGE_TAG" \
    --wait \
    --timeout 10m

print_status "Helm deployment successful"

# Wait for rollout
echo ""
echo -e "${BLUE}Waiting for deployment rollout...${NC}"
kubectl rollout status deployment/${RELEASE_NAME}-frontend -n "$NAMESPACE" --timeout=5m
print_status "Deployment rolled out successfully"

# Show deployment status
echo ""
echo -e "${BLUE}Deployment Status:${NC}"
kubectl get deployments -n "$NAMESPACE"
echo ""
kubectl get pods -n "$NAMESPACE"
echo ""
kubectl get ingress -n "$NAMESPACE"

# Print success message
echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}   Deployment Complete!                      ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "Image Tag:   ${YELLOW}$IMAGE_TAG${NC}"
echo -e "Namespace:   ${YELLOW}$NAMESPACE${NC}"
echo ""
echo -e "Access the application at: ${BLUE}https://stage.onethought.app${NC}"
echo ""

