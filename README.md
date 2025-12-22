# OneThought Infrastructure

This repository contains deployment infrastructure for OneThought, supporting both:
- **DigitalOcean VPS** (single server, Docker Compose) - **Current/Recommended for Beta**
- **AWS EKS** (Kubernetes) - Future migration path

---

## 🚀 Quick Start: DigitalOcean VPS (Recommended for Beta)

**Deploy Stage and Production on a single VPS in one day.**

### Prerequisites
- DigitalOcean account
- Domain with DNS access
- SSH access to VPS

### One-Day Setup

1. **Create Droplet** (2 vCPU / 4 GB RAM, Ubuntu 22.04)
2. **Point DNS** to VPS IP:
   ```
   A    @       <VPS_IP>
   A    stage   <VPS_IP>
   ```
3. **SSH and clone all repositories**:
   ```bash
   ssh root@<VPS_IP>
   cd /opt
   git clone https://github.com/Kaz1miR-nevo/onethought-infra.git
   git clone https://github.com/Kaz1miR-nevo/onethought-api.git
   git clone https://github.com/Kaz1miR-nevo/onepost.git OneThought
   cd onethought-infra/deploy
   ```
4. **Run bootstrap scripts**:
   ```bash
   chmod +x scripts/*.sh
   ./scripts/00_server_bootstrap.sh
   ./scripts/01_install_docker.sh
   ./scripts/02_configure_firewall.sh
   ./scripts/03_setup_nginx.sh
   ./scripts/04_setup_https_certbot.sh  # Prompts for domains/email
   ```
5. **Configure environment**:
   ```bash
   cd env
   cp stage.api.env.example stage.api.env
   cp stage.web.env.example stage.web.env
   cp prod.api.env.example prod.api.env
   cp prod.web.env.example prod.web.env
   # Edit files and fill in your secrets
   ```
6. **Deploy**:
   ```bash
   cd ..
   ./scripts/05_deploy_stage.sh
   ./scripts/06_deploy_prod.sh
   ```
7. **Verify**:
   ```bash
   ./scripts/07_healthcheck.sh
   curl https://stage.domain.com/api/health
   curl https://domain.com/api/health
   ```

**Cost**: ~$29/month (Droplet + backups)

### Important Notes for DevOps

- **All 3 repositories must be cloned** to `/opt/` on the server:
  - `onethought-infra` → `/opt/onethought-infra`
  - `onethought-api` → `/opt/onethought-api`
  - `onepost` → `/opt/OneThought` (note the directory name)

- **Environment files** must be created from `.example` files and filled with real secrets
- **Never commit** `.env` files to git
- **Redis** is optional but recommended (configured in env files)
- **Scripts are idempotent** - safe to run multiple times

### Troubleshooting

If deployment fails:
1. Check that all repositories are cloned: `ls -la /opt/`
2. Verify environment files exist: `ls -la /opt/onethought-infra/deploy/env/*.env`
3. Check Docker is running: `docker ps`
4. Review logs: `docker compose -p onethought_stage -f docker-compose.stage.yml logs`

**Full Documentation**: 
- [deploy/docs/DEPLOY_DO_VPS.md](deploy/docs/DEPLOY_DO_VPS.md) - Complete deployment guide
- [deploy/docs/RUNBOOK.md](deploy/docs/RUNBOOK.md) - Operational procedures
- [deploy/docs/SECRETS_AND_ENV.md](deploy/docs/SECRETS_AND_ENV.md) - Environment variables
- [deploy/QUICK_START.md](deploy/QUICK_START.md) - Quick reference checklist

---

## 🏗️ AWS Kubernetes Infrastructure (Future)

This directory contains the complete infrastructure-as-code for deploying OneThought on AWS EKS.

> **Note**: For beta/hobby projects, use DigitalOcean VPS above. Migrate to AWS EKS when you need auto-scaling, high availability, or enterprise features.

---

## 🔥 Stage vs Production Separation

### Key Differences Summary

| Component | Stage | Production |
|-----------|-------|------------|
| **EKS Cluster** | `onethought-stage-eks` | `onethought-prod-eks` |
| **VPC CIDR** | `10.0.0.0/16` | `10.1.0.0/16` |
| **ECR Repository** | `onethought-stage-frontend` | `onethought-prod-frontend` |
| **AWS Secrets** | `onethought-stage/app-secrets` | `onethought-prod/app-secrets` |
| **Domain** | `stage.onethought.app` | `birka.one` |
| **IAM Role (GitHub)** | `onethought-stage-github-actions` | `onethought-prod-github-actions` |
| **Terraform Workspace** | `stage` | `prod` |
| **Helm Values** | `values.stage.yaml` | `values.prod.yaml` |
| **Git Trigger** | Push to `main` | GitHub Release |
| **Log Level** | `debug` | `info` |
| **Min Replicas** | 2 | 3 |
| **Instance Types** | `t3.medium` | `t3.large`, `t3.xlarge` |
| **WAF Enabled** | No | Yes |
| **Spot Instances** | Yes (cost saving) | No (stability) |

### Terraform State Separation

Each environment uses a **separate Terraform workspace**:

```bash
# Stage deployment
terraform workspace select stage
terraform apply -var-file=environments/stage.tfvars

# Production deployment
terraform workspace select prod
terraform apply -var-file=environments/prod.tfvars
```

For production use, enable **remote S3 backend** (uncomment in `main.tf`):

```hcl
backend "s3" {
  bucket         = "onethought-terraform-state"
  key            = "infrastructure/terraform.tfstate"  # Different per workspace
  region         = "eu-central-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

### Helm Values Separation

- `values.stage.yaml` — stage-specific settings
- `values.prod.yaml` — production-specific settings

Key differences in values files:
- Image repository: `onethought-stage-frontend` vs `onethought-prod-frontend`
- Environment: `NEXT_PUBLIC_APP_ENV=stage` vs `NEXT_PUBLIC_APP_ENV=prod`
- Secrets: `onethought-stage/app-secrets` vs `onethought-prod/app-secrets`
- Resources: Lower limits for stage, higher for prod

### CI/CD Separation

| Workflow | Trigger | Cluster | Values File |
|----------|---------|---------|-------------|
| `deploy-stage.yml` | Push to `main` | `onethought-stage-eks` | `values.stage.yaml` |
| `deploy-prod.yml` | GitHub Release | `onethought-prod-eks` | `values.prod.yaml` |

Production deployments require **manual approval** via GitHub Environments.

### AWS Secrets Manager

Secrets are stored separately:
- Stage: `onethought-stage/app-secrets`
- Prod: `onethought-prod/app-secrets`

**Never share secrets between environments!**

---

## 📁 Structure

```
onethought-infra/
├── deploy/                 # 🆕 DigitalOcean VPS deployment
│   ├── docker-compose.stage.yml
│   ├── docker-compose.prod.yml
│   ├── env/                # Environment templates (.example files)
│   ├── nginx/              # Nginx configurations
│   ├── redis/              # Redis configuration
│   ├── scripts/            # Bootstrap & deployment scripts
│   ├── docs/              # VPS deployment documentation
│   └── QUICK_START.md     # Quick reference
├── terraform/              # AWS Infrastructure (EKS, VPC, IAM, ECR)
│   ├── environments/       # Stage and Prod tfvars
│   │   ├── stage.tfvars    # Stage configuration
│   │   └── prod.tfvars     # Production configuration
│   └── modules/            # Terraform modules
├── helm/                   # Kubernetes Helm Charts
│   └── onethought/         # Main application chart
│       ├── values.yaml     # Default values
│       ├── values.stage.yaml  # Stage overrides
│       └── values.prod.yaml   # Prod overrides
├── k8s/
│   └── monitoring/        # Grafana, Loki, Prometheus stack
├── scripts/               # AWS/K8s deployment scripts
├── ci-cd/                 # Reference CI/CD workflows
├── local/                 # Local development helpers
└── docs/                  # AWS/K8s documentation
```

**Note**: For DigitalOcean VPS deployment, use files in `deploy/` directory. For AWS EKS, use `terraform/` and `helm/`.

## 🚀 Quick Start

### Prerequisites

- AWS CLI v2 configured
- Terraform >= 1.6.0
- kubectl >= 1.28
- Helm >= 3.13

---

## 🟢 Deploy STAGE from Scratch

```bash
# 1. Initialize Terraform
cd infra/terraform/
terraform init

# 2. Create and select stage workspace
terraform workspace new stage || terraform workspace select stage

# 3. Review the plan
terraform plan -var-file=environments/stage.tfvars

# 4. Apply infrastructure
terraform apply -var-file=environments/stage.tfvars

# 5. Configure kubectl
aws eks update-kubeconfig --name onethought-stage-eks --region eu-central-1

# 6. Verify cluster access
kubectl cluster-info
kubectl get nodes

# 7. Install monitoring stack
cd ../scripts/
chmod +x *.sh
./install-monitoring.sh stage

# 8. Configure secrets in AWS Secrets Manager
aws secretsmanager update-secret \
  --secret-id onethought-stage/app-secrets \
  --secret-string '{
    "SUPABASE_URL": "https://cgiqlvscetphwvvffdlj.supabase.co",
    "SUPABASE_ANON_KEY": "your-anon-key",
    "SUPABASE_SERVICE_KEY": "your-service-key",
    "JWT_SECRET": "your-jwt-secret"
  }'

# 9. Deploy application
./deploy-stage.sh $(git rev-parse --short HEAD)

# 10. Verify deployment
kubectl get pods -n onethought
kubectl get ingress -n onethought

# 11. Test via port-forward (before DNS)
./kubectl-port-forward-app.sh
# Open http://localhost:3000
```

---

## 🔴 Deploy PRODUCTION from Scratch

⚠️ **WARNING**: Production deployment. Test on stage first!

```bash
# 1. Initialize Terraform (if not done)
cd infra/terraform/
terraform init

# 2. Create and select prod workspace
terraform workspace new prod || terraform workspace select prod

# 3. Review the plan CAREFULLY
terraform plan -var-file=environments/prod.tfvars

# 4. Apply infrastructure (requires confirmation)
terraform apply -var-file=environments/prod.tfvars

# 5. Configure kubectl for production
aws eks update-kubeconfig --name onethought-prod-eks --region eu-central-1

# 6. Install monitoring stack
cd ../scripts/
./install-monitoring.sh prod

# 7. Configure production secrets
aws secretsmanager update-secret \
  --secret-id onethought-prod/app-secrets \
  --secret-string '{
    "SUPABASE_URL": "https://hutrzgxhgnkkkvwmlytm.supabase.co",
    "SUPABASE_ANON_KEY": "your-prod-anon-key",
    "SUPABASE_SERVICE_KEY": "your-prod-service-key",
    "JWT_SECRET": "your-prod-jwt-secret"
  }'

# 8. Deploy application (via CI/CD or manual)
./deploy-prod.sh $(git rev-parse --short HEAD)

# 9. Verify
kubectl get pods -n onethought
kubectl get ingress -n onethought
```

---

## 🔄 Promote Changes: Stage → Production

1. **Test thoroughly on Stage**
   - Verify all features work
   - Check logs in Grafana
   - Run smoke tests

2. **Create a GitHub Release**
   - Go to GitHub → Releases → Create new release
   - Tag format: `v1.0.0`
   - This triggers `deploy-prod.yml` workflow

3. **Approve the deployment**
   - Go to GitHub Actions → Deploy to Production
   - Click "Review deployments" → Approve

4. **Monitor rollout**
   ```bash
   kubectl rollout status deployment/onethought-frontend -n onethought
   kubectl get pods -n onethought
   ```

5. **If something goes wrong**
   ```bash
   # Rollback to previous version
   helm rollback onethought -n onethought
   ```

---

## 💻 Local Development (No Docker/Kubernetes)

For local development, you don't need any infrastructure:

```bash
# From project root (not infra/)
npm install
npm run dev
# Open http://localhost:3000
```

Create `.env.local` with:
```env
NEXT_PUBLIC_SUPABASE_URL=https://cgiqlvscetphwvvffdlj.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
NEXT_PUBLIC_APP_ENV=stage
```

⚠️ **Always use STAGE Supabase credentials for local development!**

## 🌍 Environments Summary

| Environment | Branch/Trigger | Terraform Workspace | EKS Cluster | Domain |
|-------------|----------------|---------------------|-------------|--------|
| Stage | Push to `main` | `stage` | `onethought-stage-eks` | stage.onethought.app |
| Production | GitHub Release | `prod` | `onethought-prod-eks` | birka.one |

## 📦 Required Secrets (Per Environment)

### Stage Secrets (`onethought-stage/app-secrets`)
```json
{
  "SUPABASE_URL": "https://cgiqlvscetphwvvffdlj.supabase.co",
  "SUPABASE_ANON_KEY": "stage-anon-key",
  "SUPABASE_SERVICE_KEY": "stage-service-key",
  "JWT_SECRET": "stage-jwt-secret"
}
```

### Production Secrets (`onethought-prod/app-secrets`)
```json
{
  "SUPABASE_URL": "https://hutrzgxhgnkkkvwmlytm.supabase.co",
  "SUPABASE_ANON_KEY": "prod-anon-key",
  "SUPABASE_SERVICE_KEY": "prod-service-key",
  "JWT_SECRET": "prod-jwt-secret"
}
```

## 🔐 GitHub Actions Setup

The workflows are located in `.github/workflows/` (root, not in `infra/ci-cd/`).

### Repository Secrets (Required)
| Secret | Description |
|--------|-------------|
| `AWS_ACCOUNT_ID` | Your AWS account ID (12 digits) |

### GitHub Environments (Required)
| Environment | Protection Rules |
|-------------|------------------|
| `stage` | None (auto-deploy) |
| `production` | Requires reviewer approval |

### AWS OIDC Setup
Terraform creates the OIDC provider and IAM roles automatically:
- `onethought-stage-github-actions` — for stage deployments
- `onethought-prod-github-actions` — for production deployments

## 📊 Monitoring

Access Grafana:
```bash
./scripts/kubectl-port-forward-grafana.sh
# Open http://localhost:3000
# Default: admin / prom-operator
```

## 📖 Documentation

### DigitalOcean VPS (Current)
| Document | Purpose |
|----------|---------|
| [deploy/QUICK_START.md](deploy/QUICK_START.md) | Quick setup checklist |
| [deploy/docs/DEPLOY_DO_VPS.md](deploy/docs/DEPLOY_DO_VPS.md) | Complete deployment guide |
| [deploy/docs/RUNBOOK.md](deploy/docs/RUNBOOK.md) | Operational procedures |
| [deploy/docs/SECRETS_AND_ENV.md](deploy/docs/SECRETS_AND_ENV.md) | Environment variables |
| [deploy/docs/REDIS_USAGE_GUIDE.md](deploy/docs/REDIS_USAGE_GUIDE.md) | Redis configuration |
| [deploy/docs/MIGRATION_FUTURE_AWS_K8S.md](deploy/docs/MIGRATION_FUTURE_AWS_K8S.md) | Future migration guide |

### AWS EKS (Future)
| Document | Purpose |
|----------|---------|
| [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) | Step-by-step deployment |
| [docs/LOCAL_DEVELOPMENT.md](docs/LOCAL_DEVELOPMENT.md) | Run without K8s |
| [docs/SECURITY_CHECKLIST.md](docs/SECURITY_CHECKLIST.md) | Security requirements |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues |
| [docs/HEALTH_CHECKLIST.md](docs/HEALTH_CHECKLIST.md) | Pre-production checklist |

## ✅ Verification Checklist

Run this checklist after any infrastructure changes:

### Terraform Separation
```bash
# Verify workspaces exist
terraform workspace list

# Verify stage resources
terraform workspace select stage
terraform show | grep -E "(cluster_name|vpc_cidr|name_prefix)"
# Should show: onethought-stage-*

# Verify prod resources
terraform workspace select prod
terraform show | grep -E "(cluster_name|vpc_cidr|name_prefix)"
# Should show: onethought-prod-*
```

### Kubernetes/Helm Separation
```bash
# Verify stage cluster
aws eks update-kubeconfig --name onethought-stage-eks --region eu-central-1
kubectl cluster-info
# Should show: onethought-stage-eks

# Verify prod cluster (different kubeconfig)
aws eks update-kubeconfig --name onethought-prod-eks --region eu-central-1
kubectl cluster-info
# Should show: onethought-prod-eks
```

### Secrets Separation
```bash
# List stage secrets
aws secretsmanager list-secrets --filter Key=name,Values=onethought-stage

# List prod secrets
aws secretsmanager list-secrets --filter Key=name,Values=onethought-prod
```

### CI/CD Verification
Check in `.github/workflows/`:
- `deploy-stage.yml` uses `EKS_CLUSTER_NAME: onethought-stage-eks`
- `deploy-prod.yml` uses `EKS_CLUSTER_NAME: onethought-prod-eks`

## ⚠️ Important Rules

1. **Always test on stage first**
2. **Never commit secrets to git**
3. **Production deployments require manual approval**
4. **Don't modify RLS policies directly in production**
5. **Use migrations for database changes**
6. **Never share credentials between stage and prod**
7. **Always verify the correct workspace/cluster before applying changes**

## 🚫 What NOT to Do

| ❌ Don't | ✅ Do Instead |
|----------|--------------|
| Use prod Supabase locally | Always use stage for development |
| Share secrets between envs | Keep stage/prod secrets separate |
| Push directly to `prod` branch | Use PRs and releases |
| Apply Terraform without checking workspace | Always run `terraform workspace show` first |
| Delete infrastructure without backup | Create backups, test rollback |

## 🆘 Need Help?

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review Grafana dashboards: `./scripts/kubectl-port-forward-grafana.sh`
3. Check pod logs: `kubectl logs -l app.kubernetes.io/component=frontend -n onethought`
4. Describe problematic pods: `kubectl describe pods -n onethought`

## 📋 Files Changed During This Audit

This audit verified and/or updated the following files:

### Verified (No Changes Needed)
- `infra/terraform/environments/stage.tfvars` - ✅ Correctly uses `environment = "stage"`
- `infra/terraform/environments/prod.tfvars` - ✅ Correctly uses `environment = "prod"`
- `infra/terraform/main.tf` - ✅ Uses `${project_name}-${environment}` naming
- `infra/terraform/modules/secrets/main.tf` - ✅ Uses `${name_prefix}/app-secrets`
- `infra/helm/onethought/values.stage.yaml` - ✅ Correctly configured for stage
- `infra/helm/onethought/values.prod.yaml` - ✅ Correctly configured for prod
- `.github/workflows/deploy-stage.yml` - ✅ Uses `onethought-stage-eks`
- `.github/workflows/deploy-prod.yml` - ✅ Uses `onethought-prod-eks`

### Updated
- `infra/README.md` - Added Stage/Prod separation section and deployment commands
