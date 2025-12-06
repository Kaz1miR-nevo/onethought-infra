# OneThought Terraform Infrastructure

## 📁 Structure

```
terraform/
├── main.tf                    # Main configuration & providers
├── variables.tf               # Variable definitions
├── outputs.tf                 # Output values
├── network.tf                 # VPC endpoints & NACLs
├── eks.tf                     # EKS addons & namespaces
├── ecr.tf                     # ECR additional config
├── alb.tf                     # ALB & certificates
├── grafana-loki.tf            # Monitoring infrastructure
├── environments/
│   ├── stage.tfvars           # Stage environment values
│   └── prod.tfvars            # Production environment values
├── helm-values/
│   ├── prometheus-values.yaml # Prometheus stack config
│   ├── loki-values.yaml       # Loki config
│   └── promtail-values.yaml   # Promtail config
└── modules/
    ├── vpc/                   # VPC module
    ├── eks/                   # EKS cluster module
    ├── ecr/                   # Container registry module
    ├── alb-controller/        # AWS LB Controller module
    ├── kms/                   # Encryption keys module
    ├── secrets/               # Secrets Manager module
    └── waf/                   # WAF module
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.6.0
3. **kubectl** >= 1.28
4. **helm** >= 3.13

### First-time Setup

```bash
# Initialize Terraform
cd terraform/
terraform init

# Create workspaces for environments (run ONCE)
terraform workspace new stage
terraform workspace new prod
```

### ⚠️ IMPORTANT: Workspace Verification

**ALWAYS verify your workspace before running any commands:**

```bash
# Check current workspace
terraform workspace show

# List all workspaces
terraform workspace list
```

### Deploy STAGE Infrastructure

```bash
# 1. Select stage workspace
terraform workspace select stage

# 2. Verify you're in the right workspace
terraform workspace show
# Should output: stage

# 3. Plan and apply
terraform plan -var-file=environments/stage.tfvars
terraform apply -var-file=environments/stage.tfvars
```

### Deploy PRODUCTION Infrastructure

⚠️ **WARNING: Production environment - proceed with extreme caution!**

```bash
# 1. Select prod workspace
terraform workspace select prod

# 2. VERIFY you're in the right workspace
terraform workspace show
# Should output: prod

# 3. Plan CAREFULLY review the output!
terraform plan -var-file=environments/prod.tfvars

# 4. Apply only after thorough review
terraform apply -var-file=environments/prod.tfvars
```

### Resource Naming Convention

All resources use the naming convention: `{project_name}-{environment}-{resource}`

| Environment | Example Resources |
|-------------|-------------------|
| Stage | `onethought-stage-eks`, `onethought-stage-frontend`, `onethought-stage/app-secrets` |
| Prod | `onethought-prod-eks`, `onethought-prod-frontend`, `onethought-prod/app-secrets` |

### Configure kubectl

After successful deployment:

```bash
# Get the command from Terraform output
terraform output configure_kubectl

# Or run directly:
aws eks update-kubeconfig --name onethought-stage-eks --region eu-central-1
```

## 📦 What Gets Created

### Network (VPC Module)
- VPC with public/private subnets across 3 AZs
- Internet Gateway
- NAT Gateways (one per AZ)
- Route tables
- VPC Flow Logs (production only)

### Kubernetes (EKS Module)
- EKS cluster with OIDC provider
- Managed node groups with autoscaling
- EKS addons (VPC CNI, CoreDNS, Kube-proxy, EBS CSI)
- Cluster Autoscaler

### Container Registry (ECR Module)
- ECR repositories for frontend & backend
- Lifecycle policies for image retention
- Image scanning enabled

### Load Balancer (ALB Controller Module)
- AWS Load Balancer Controller
- IAM roles for service accounts
- SSL certificate (ACM)

### Security
- KMS keys for encryption at rest
- Secrets Manager for application secrets
- WAF with rate limiting and managed rules (production)
- VPC endpoints for private AWS access

### Monitoring
- S3 bucket for Loki logs
- IAM roles for Grafana and Loki
- Prometheus stack (kube-prometheus-stack)
- Loki for log aggregation
- Promtail for log collection

## 🔐 Secrets Management

Secrets are stored in AWS Secrets Manager. After initial creation, update the placeholder values:

```bash
aws secretsmanager update-secret \
  --secret-id onethought-stage/app-secrets \
  --secret-string '{
    "SUPABASE_URL": "https://your-project.supabase.co",
    "SUPABASE_ANON_KEY": "your-anon-key",
    "JWT_SECRET": "your-jwt-secret"
  }'
```

## 🔧 Customization

### Adding Node Groups

Edit `environments/stage.tfvars` or `environments/prod.tfvars`:

```hcl
node_groups = {
  general = {
    instance_types = ["t3.medium"]
    min_size       = 2
    max_size       = 5
    desired_size   = 2
    disk_size      = 50
    labels = {}
    taints = []
  }
  
  # Add a new node group
  high-memory = {
    instance_types = ["r6i.large"]
    min_size       = 0
    max_size       = 3
    desired_size   = 0
    disk_size      = 100
    labels = {
      workload = "memory-intensive"
    }
    taints = [{
      key    = "workload"
      value  = "memory-intensive"
      effect = "NO_SCHEDULE"
    }]
  }
}
```

### Enabling Route53 DNS

1. Get your hosted zone ID from Route53
2. Update tfvars:

```hcl
hosted_zone_id = "Z0123456789ABCDEF"
```

## ⚠️ Important Notes

### State Management

⚠️ **CRITICAL: Stage and Prod use different Terraform workspaces!**

Each workspace has its own isolated state, ensuring that:
- Stage changes don't affect prod
- Prod changes don't affect stage
- Each environment tracks its own resources

#### Local State (Development)

By default, Terraform uses local state files. Each workspace creates a separate state:
- `terraform.tfstate.d/stage/terraform.tfstate`
- `terraform.tfstate.d/prod/terraform.tfstate`

#### Remote State (Production - Recommended)

For production use, enable remote S3 state with locking:

1. Create S3 bucket and DynamoDB table for state locking:
```bash
aws s3 mb s3://onethought-terraform-state --region eu-central-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

2. Uncomment backend configuration in `main.tf`:
```hcl
backend "s3" {
  bucket         = "onethought-terraform-state"
  key            = "infrastructure/terraform.tfstate"
  region         = "eu-central-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

3. Migrate state:
```bash
terraform init -migrate-state
```

With S3 backend, workspaces are stored as:
- `s3://onethought-terraform-state/env:/stage/infrastructure/terraform.tfstate`
- `s3://onethought-terraform-state/env:/prod/infrastructure/terraform.tfstate`

### Destroy Order

When destroying infrastructure, ensure proper order:

```bash
# 1. Delete Helm releases first
helm uninstall onethought -n onethought

# 2. Then destroy Terraform
terraform destroy -var-file=environments/stage.tfvars
```

### Cost Optimization

- Stage uses spot instances by default
- Consider Savings Plans for production
- Review unused resources regularly

## 🆘 Troubleshooting

### Common Issues

**EKS not accessible:**
```bash
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

**Node group not scaling:**
- Check Cluster Autoscaler logs
- Verify IAM permissions
- Check for pod disruption budgets

**ALB not created:**
- Check ALB Controller logs
- Verify Ingress annotations
- Check subnet tags

## 📚 Related Documentation

- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Helm Chart Guide](../helm/README.md)

