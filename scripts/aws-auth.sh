#!/bin/bash
# =============================================================================
# AWS Authentication Helper Script
# =============================================================================
# Helps configure AWS authentication for deployment
# Usage: ./aws-auth.sh [stage|prod]
# =============================================================================

set -euo pipefail

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ENVIRONMENT="${1:-stage}"
REGION="eu-central-1"
CLUSTER_NAME="onethought-${ENVIRONMENT}-eks"

echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}   AWS Authentication Setup                 ${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""

# Check if AWS CLI is configured
echo -e "${BLUE}Checking AWS CLI configuration...${NC}"
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query "Account" --output text)
    AWS_USER=$(aws sts get-caller-identity --query "Arn" --output text)
    echo -e "${GREEN}[✓] AWS CLI configured${NC}"
    echo "  Account: $AWS_ACCOUNT"
    echo "  User: $AWS_USER"
else
    echo -e "${YELLOW}AWS CLI not configured. Please run:${NC}"
    echo "  aws configure"
    echo ""
    echo "Or set environment variables:"
    echo "  export AWS_ACCESS_KEY_ID=<your-key>"
    echo "  export AWS_SECRET_ACCESS_KEY=<your-secret>"
    echo "  export AWS_REGION=$REGION"
    exit 1
fi

# Configure kubectl
echo ""
echo -e "${BLUE}Configuring kubectl for EKS...${NC}"
if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$REGION" &> /dev/null; then
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION" --alias "$CLUSTER_NAME"
    echo -e "${GREEN}[✓] kubectl configured for $CLUSTER_NAME${NC}"
else
    echo -e "${YELLOW}Cluster $CLUSTER_NAME not found in region $REGION${NC}"
    echo "Available clusters:"
    aws eks list-clusters --region "$REGION" --output table
fi

# Login to ECR
echo ""
echo -e "${BLUE}Logging into ECR...${NC}"
aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "${AWS_ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com" 2>/dev/null || {
    echo -e "${YELLOW}Docker not available or login failed${NC}"
    echo "This is OK if you're only deploying (not building images)"
}

# Verify access
echo ""
echo -e "${BLUE}Verifying cluster access...${NC}"
if kubectl cluster-info &> /dev/null; then
    echo -e "${GREEN}[✓] Can connect to Kubernetes cluster${NC}"
    echo ""
    kubectl cluster-info
else
    echo -e "${YELLOW}Cannot connect to cluster${NC}"
    echo "Check your VPN connection or network settings"
fi

echo ""
echo -e "${GREEN}Authentication setup complete!${NC}"

