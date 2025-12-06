# OneThought Deployment Guide

## Overview

This guide provides step-by-step instructions for deploying the complete OneThought infrastructure.

## Prerequisites

Before starting, ensure you have:

- [ ] AWS CLI v2 installed and configured
- [ ] Terraform >= 1.6.0
- [ ] kubectl >= 1.28
- [ ] Helm >= 3.13
- [ ] Docker (for building images)
- [ ] Git

## Step 1: Deploy AWS Infrastructure with Terraform

### 1.1 Initialize Terraform

```bash
cd infra/terraform

# Initialize Terraform
terraform init

# Create workspace for stage environment
terraform workspace new stage
```

### 1.2 Configure Variables

Review and update `environments/stage.tfvars`:

```hcl
# Update these values
github_org  = "your-github-org"
github_repo = "onethought"
domain_name = "onethought.app"
```

### 1.3 Plan and Apply

```bash
# Review the plan
terraform plan -var-file=environments/stage.tfvars

# Apply (this takes 15-20 minutes)
terraform apply -var-file=environments/stage.tfvars
```

### 1.4 Note the Outputs

```bash
terraform output

# Save important values:
# - cluster_name
# - ecr_frontend_url
# - github_actions_role_arn
# - configure_kubectl command
```

## Step 2: Configure kubectl

```bash
# Get the configure command from Terraform output
aws eks update-kubeconfig --name onethought-stage-eks --region eu-central-1

# Verify connectivity
kubectl cluster-info
kubectl get nodes
```

## Step 3: Install Monitoring Stack

```bash
cd infra/scripts

# Make scripts executable
chmod +x *.sh

# Install monitoring
./install-monitoring.sh stage
```

### Access Grafana

```bash
./kubectl-port-forward-grafana.sh
# Open http://localhost:3000
# Default credentials: admin / prom-operator
```

## Step 4: Configure Secrets

### 4.1 Update AWS Secrets Manager

```bash
# Get secret name from Terraform output
aws secretsmanager update-secret \
  --secret-id onethought-stage/app-secrets \
  --secret-string '{
    "SUPABASE_URL": "https://cgiqlvscetphwvvffdlj.supabase.co",
    "SUPABASE_ANON_KEY": "your-anon-key",
    "SUPABASE_SERVICE_KEY": "your-service-key",
    "JWT_SECRET": "your-jwt-secret"
  }'
```

### 4.2 Install External Secrets Operator

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets \
  --create-namespace
```

### 4.3 Apply ClusterSecretStore

```bash
kubectl apply -f infra/k8s/monitoring/cluster-secret-store.yaml
```

## Step 5: Build and Push Docker Image

### 5.1 Login to ECR

```bash
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  $(terraform output -raw ecr_frontend_url | cut -d'/' -f1)
```

### 5.2 Build Image

```bash
cd /path/to/onethought

docker build -t onethought-frontend:latest \
  --build-arg NODE_ENV=production \
  --build-arg NEXT_PUBLIC_APP_ENV=stage \
  -f infra/docker/Dockerfile .
```

### 5.3 Push to ECR

```bash
ECR_URL=$(cd infra/terraform && terraform output -raw ecr_frontend_url)

docker tag onethought-frontend:latest $ECR_URL:latest
docker tag onethought-frontend:latest $ECR_URL:$(git rev-parse --short HEAD)

docker push $ECR_URL:latest
docker push $ECR_URL:$(git rev-parse --short HEAD)
```

## Step 6: Deploy Application with Helm

### 6.1 Deploy to Stage

```bash
cd infra/scripts
./deploy-stage.sh $(git rev-parse --short HEAD)
```

### 6.2 Verify Deployment

```bash
kubectl get pods -n onethought
kubectl get ingress -n onethought
kubectl logs -l app.kubernetes.io/component=frontend -n onethought
```

## Step 7: Configure DNS (Optional)

If using Route53:

1. Get ALB hostname:
   ```bash
   kubectl get ingress -n onethought -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
   ```

2. Create CNAME record pointing `stage.onethought.app` to ALB hostname

## Step 8: Test Without External Traffic

Before configuring DNS and exposing the app publicly, test via port-forward:

### Option 1: Port Forward to App (Recommended for Testing)

```bash
# Use the convenience script
./scripts/kubectl-port-forward-app.sh

# Or manually:
kubectl port-forward svc/onethought-frontend 3000:3000 -n onethought
```

Open http://localhost:3000 in your browser.

### Option 2: Port Forward to Specific Pod

```bash
# Get pod name
kubectl get pods -n onethought

# Forward to specific pod
kubectl port-forward pod/<pod-name> 3000:3000 -n onethought
```

### Health Check Test

```bash
curl http://localhost:3000/api/health
# Expected: {"status":"ok","timestamp":"...","environment":"stage","checks":{"app":"ok"}}
```

## Step 9: Enable External Traffic (When Ready)

Once testing is complete:

1. **Configure ACM Certificate** (if not done):
   ```bash
   # Verify certificate is issued
   aws acm describe-certificate --certificate-arn <your-cert-arn>
   ```

2. **Update Ingress with Certificate**:
   Edit `values.stage.yaml`:
   ```yaml
   ingress:
     annotations:
       alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
   ```

3. **Redeploy**:
   ```bash
   ./scripts/deploy-stage.sh
   ```

4. **Configure DNS**:
   - Get ALB hostname:
     ```bash
     kubectl get ingress -n onethought -o jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}'
     ```
   - Create CNAME record: `stage.onethought.app` → ALB hostname

5. **Verify**:
   ```bash
   curl https://stage.onethought.app/api/health
   ```

## Step 10: Verify Everything

### Check Application

### Check Monitoring

```bash
./kubectl-port-forward-grafana.sh
# Verify dashboards show data
```

### Check Logs

```bash
# In Grafana, go to Explore
# Select Loki datasource
# Query: {namespace="onethought"}
```

## Production Deployment

### Additional Steps for Production

1. **Update to production tfvars**:
   ```bash
   terraform workspace new prod
   terraform apply -var-file=environments/prod.tfvars
   ```

2. **Enable WAF** (automatically enabled for prod in Terraform)

3. **Configure SSL Certificate**:
   - Verify ACM certificate in AWS Console
   - Update Ingress annotations with certificate ARN

4. **Update Secrets** for production Supabase

5. **Deploy**:
   ```bash
   ./deploy-prod.sh v1.0.0
   ```

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n onethought
kubectl logs <pod-name> -n onethought
```

### Ingress not working

```bash
kubectl describe ingress onethought -n onethought
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Secrets not available

```bash
kubectl get externalsecrets -n onethought
kubectl describe externalsecret -n onethought
```

## Rollback

If something goes wrong:

```bash
# Quick rollback
helm rollback onethought -n onethought

# Or to specific revision
helm history onethought -n onethought
helm rollback onethought <revision> -n onethought
```

## Cleanup

To destroy everything:

```bash
# 1. Delete Helm release
helm uninstall onethought -n onethought

# 2. Delete monitoring
helm uninstall prometheus -n monitoring
helm uninstall loki -n monitoring

# 3. Destroy Terraform (⚠️ irreversible!)
cd infra/terraform
terraform destroy -var-file=environments/stage.tfvars
```

