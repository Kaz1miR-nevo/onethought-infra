#!/bin/bash
# =============================================================================
# OneThought Production Deployment Script
# =============================================================================
# Deploys the application to the production environment
# Usage: ./deploy-prod.sh [image-tag]
# 
# ⚠️ WARNING: This script deploys to PRODUCTION!
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="prod"
CLUSTER_NAME="onethought-prod-eks"
REGION="eu-central-1"
NAMESPACE="onethought"
RELEASE_NAME="onethought"
CHART_PATH="../helm/onethought"
VALUES_FILE="../helm/onethought/values.prod.yaml"

# Get image tag from argument
IMAGE_TAG="${1:-}"

# Print header
echo -e "${RED}=============================================${NC}"
echo -e "${RED}   ⚠️  PRODUCTION DEPLOYMENT ⚠️             ${NC}"
echo -e "${RED}=============================================${NC}"
echo ""

# Require image tag for production
if [ -z "$IMAGE_TAG" ]; then
    echo -e "${RED}ERROR: Image tag is required for production deployment${NC}"
    echo "Usage: ./deploy-prod.sh <image-tag>"
    echo "Example: ./deploy-prod.sh v1.0.0"
    exit 1
fi

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

# Confirmation prompt
echo -e "${YELLOW}You are about to deploy to PRODUCTION!${NC}"
echo ""
echo "  Environment: $ENVIRONMENT"
echo "  Cluster:     $CLUSTER_NAME"
echo "  Image Tag:   $IMAGE_TAG"
echo ""
read -p "Are you sure you want to continue? Type 'DEPLOY PROD' to confirm: " confirmation
if [ "$confirmation" != "DEPLOY PROD" ]; then
    echo "Deployment cancelled."
    exit 0
fi
echo ""

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
    print_error "Not authenticated to AWS"
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

# Check cluster health - MANDATORY for production
echo ""
echo -e "${BLUE}Checking cluster health (mandatory for production)...${NC}"
if ! ./check-cluster-health.sh; then
    print_error "Cluster health check failed - deployment aborted"
    exit 1
fi
print_status "Cluster health check passed"

# Verify image exists in ECR
echo ""
echo -e "${BLUE}Verifying image exists in ECR...${NC}"
ECR_REPO="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/onethought-prod-frontend"
if ! aws ecr describe-images --repository-name "onethought-prod-frontend" --image-ids imageTag="$IMAGE_TAG" --region "$REGION" &> /dev/null; then
    print_error "Image $ECR_REPO:$IMAGE_TAG not found in ECR"
    exit 1
fi
print_status "Image verified: $ECR_REPO:$IMAGE_TAG"

# Create backup of current deployment
echo ""
echo -e "${BLUE}Creating backup of current deployment...${NC}"
BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
kubectl get all -n "$NAMESPACE" -o yaml > "$BACKUP_DIR/resources.yaml" 2>/dev/null || true
helm get values "$RELEASE_NAME" -n "$NAMESPACE" > "$BACKUP_DIR/values.yaml" 2>/dev/null || true
print_status "Backup created: $BACKUP_DIR"

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
    --timeout 15m \
    --atomic

print_status "Helm deployment successful"

# Wait for rollout
echo ""
echo -e "${BLUE}Waiting for deployment rollout...${NC}"
kubectl rollout status deployment/${RELEASE_NAME}-frontend -n "$NAMESPACE" --timeout=10m
print_status "Deployment rolled out successfully"

# Verify deployment health
echo ""
echo -e "${BLUE}Verifying deployment health...${NC}"
sleep 30  # Wait for pods to stabilize

READY_PODS=$(kubectl get deployment/${RELEASE_NAME}-frontend -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
DESIRED_PODS=$(kubectl get deployment/${RELEASE_NAME}-frontend -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

if [ "$READY_PODS" -lt "$DESIRED_PODS" ]; then
    print_warning "Not all pods are ready: $READY_PODS / $DESIRED_PODS"
else
    print_status "All pods ready: $READY_PODS / $DESIRED_PODS"
fi

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
echo -e "${GREEN}   Production Deployment Complete!          ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "Environment: ${YELLOW}$ENVIRONMENT${NC}"
echo -e "Image Tag:   ${YELLOW}$IMAGE_TAG${NC}"
echo -e "Namespace:   ${YELLOW}$NAMESPACE${NC}"
echo ""
echo -e "Access the application at: ${BLUE}https://birka.one${NC}"
echo ""
echo -e "${YELLOW}Monitor the deployment in Grafana: ./kubectl-port-forward-grafana.sh${NC}"
echo ""

