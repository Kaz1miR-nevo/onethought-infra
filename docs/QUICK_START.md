# OneThought Infrastructure - Quick Start

## 🚀 5-Minute Overview

This repository contains the complete infrastructure for OneThought:

```
infra/
├── terraform/       # AWS Infrastructure (EKS, VPC, IAM)
├── helm/           # Kubernetes Deployments
├── k8s/monitoring/ # Grafana, Loki, Prometheus
├── scripts/        # Deployment utilities
├── ci-cd/          # GitHub Actions workflows
├── docker/         # Dockerfile for the app
├── local/          # Local development setup
└── docs/           # Detailed documentation
```

## 🎯 Quick Commands

### Local Development (No K8s needed)

```bash
# In the main repo (not infra/)
npm install
npm run dev
# Open http://localhost:3000
```

### Deploy Infrastructure

```bash
# 1. Terraform
cd terraform/
terraform init
terraform apply -var-file=environments/stage.tfvars

# 2. Configure kubectl
aws eks update-kubeconfig --name onethought-stage-eks --region eu-central-1

# 3. Install monitoring
cd ../scripts/
./install-monitoring.sh stage

# 4. Deploy app
./deploy-stage.sh
```

## 📚 Full Documentation

| Document | Purpose |
|----------|---------|
| [DEPLOYMENT_GUIDE](docs/DEPLOYMENT_GUIDE.md) | Step-by-step deployment |
| [LOCAL_DEVELOPMENT](docs/LOCAL_DEVELOPMENT.md) | Run without K8s |
| [SECURITY_CHECKLIST](docs/SECURITY_CHECKLIST.md) | Security requirements |
| [TROUBLESHOOTING](docs/TROUBLESHOOTING.md) | Common issues |
| [HEALTH_CHECKLIST](docs/HEALTH_CHECKLIST.md) | Pre-production checklist |

## ⚠️ Important Rules

1. **Always test on stage first**
2. **Never commit secrets**
3. **Production requires approval**
4. **Don't modify RLS policies directly**
5. **Use migrations for database changes**

## 🆘 Need Help?

1. Check [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)
2. Review Grafana dashboards
3. Check pod logs: `kubectl logs -l app=frontend -n onethought`

