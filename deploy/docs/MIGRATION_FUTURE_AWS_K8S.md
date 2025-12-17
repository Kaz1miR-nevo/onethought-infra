# Future Migration to AWS EKS

## 📋 Overview

This document outlines the migration path from DigitalOcean VPS to AWS EKS (Kubernetes). **This is documentation only** - no code changes are made now.

## 🎯 Why Migrate?

- **Scalability**: Kubernetes auto-scaling
- **High Availability**: Multi-AZ deployment
- **Advanced Features**: Service mesh, advanced monitoring
- **Enterprise Ready**: Better for production at scale

## 📊 Current vs Future Architecture

### Current (VPS)
```
Single VPS
├── Nginx (reverse proxy)
├── Stage containers (Docker Compose)
└── Prod containers (Docker Compose)
```

### Future (AWS EKS)
```
AWS EKS Cluster
├── Ingress Controller (ALB)
├── Stage Namespace
│   ├── Web Deployment
│   ├── API Deployment
│   └── Redis Deployment
└── Prod Namespace
    ├── Web Deployment
    ├── API Deployment
    └── Redis Deployment
```

## 🔄 Migration Strategy

### Phase 1: Preparation

1. **Container Images**
   - Current: Built on VPS
   - Future: Push to AWS ECR (Elastic Container Registry)
   - Action: Update build scripts to push to ECR

2. **Environment Variables**
   - Current: `.env` files on VPS
   - Future: AWS Secrets Manager or Kubernetes Secrets
   - Action: Migrate secrets to AWS Secrets Manager

3. **Persistent Data**
   - Current: Redis data in Docker volumes
   - Future: Redis in Kubernetes with persistent volumes
   - Action: Export/import Redis data if needed

### Phase 2: Infrastructure Setup

1. **Create EKS Cluster**
   ```bash
   # Using existing Terraform in terraform/ directory
   cd terraform
   terraform init
   terraform apply
   ```

2. **Configure kubectl**
   ```bash
   aws eks update-kubeconfig --name onethought-prod-eks
   ```

3. **Deploy using Helm**
   ```bash
   cd helm/onethought
   helm install onethought . -f values.prod.yaml
   ```

### Phase 3: DNS Cutover

1. **Update DNS**
   - Point domains to ALB (Application Load Balancer)
   - ALB is created by Terraform

2. **Verify**
   - Test all endpoints
   - Monitor for issues

3. **Decommission VPS**
   - After verification period
   - Keep as backup for 30 days

## 📁 File Mapping

| Current (VPS) | Future (K8s) |
|---------------|--------------|
| `docker-compose.stage.yml` | `helm/onethought/values.stage.yaml` |
| `docker-compose.prod.yml` | `helm/onethought/values.prod.yaml` |
| `nginx/stage.conf` | `helm/onethought/templates/ingress.yaml` |
| `env/*.env` | AWS Secrets Manager |
| `scripts/*.sh` | GitHub Actions workflows |

## 🔧 Key Changes Needed

### 1. Container Registry

**Current**:
```yaml
build:
  context: ../../OneThought
```

**Future**:
```yaml
image: <account>.dkr.ecr.<region>.amazonaws.com/onethought-web:latest
```

### 2. Secrets Management

**Current**:
```bash
env_file:
  - ./env/stage.api.env
```

**Future**:
```yaml
envFrom:
  - secretRef:
      name: onethought-stage-secrets
```

### 3. Service Discovery

**Current**:
```yaml
proxy_pass http://stage_api;
```

**Future**:
```yaml
# Kubernetes service discovery
proxy_pass http://api.onethought-stage.svc.cluster.local;
```

### 4. Health Checks

**Current**:
```yaml
healthcheck:
  test: ["CMD", "wget", "..."]
```

**Future**:
```yaml
livenessProbe:
  httpGet:
    path: /api/health
    port: 3000
```

## 📋 Migration Checklist

### Pre-Migration

- [ ] Set up AWS account and IAM roles
- [ ] Create ECR repositories
- [ ] Set up EKS cluster (via Terraform)
- [ ] Migrate secrets to AWS Secrets Manager
- [ ] Update CI/CD to build and push to ECR
- [ ] Test deployment in stage namespace

### Migration Day

- [ ] Deploy to EKS stage namespace
- [ ] Verify stage environment works
- [ ] Deploy to EKS prod namespace
- [ ] Update DNS to point to ALB
- [ ] Monitor for 24 hours
- [ ] Verify all features work

### Post-Migration

- [ ] Update documentation
- [ ] Train team on Kubernetes
- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Decommission VPS (after 30 days)

## 💰 Cost Comparison

### Current (VPS)
- Droplet: $24/month
- **Total**: ~$29/month

### Future (AWS EKS)
- EKS Cluster: ~$73/month
- EC2 Nodes (2x t3.medium): ~$60/month
- ALB: ~$20/month
- ECR: ~$1/month
- **Total**: ~$154/month

**Note**: AWS costs are higher but provide:
- Auto-scaling
- High availability
- Better monitoring
- Enterprise features

## 🚀 When to Migrate?

Consider migrating when:
- Traffic exceeds single server capacity
- Need high availability (99.9%+ uptime)
- Need auto-scaling
- Team is ready for Kubernetes
- Budget allows for increased costs

## 📚 Resources

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Helm Documentation](https://helm.sh/docs/)
- [Terraform EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest)

## ⚠️ Important Notes

1. **This is a future plan** - no changes are made now
2. **VPS setup is production-ready** - migrate when needed
3. **Both setups can coexist** - test EKS while VPS runs
4. **Migration is reversible** - can rollback if needed


