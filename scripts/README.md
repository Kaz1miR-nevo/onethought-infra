# OneThought Infrastructure Scripts

## Overview

This directory contains utility scripts for managing the OneThought infrastructure.

## Scripts

### Deployment Scripts

| Script | Description |
|--------|-------------|
| `deploy-stage.sh` | Deploy to stage environment |
| `deploy-prod.sh` | Deploy to production (requires confirmation) |
| `rollback.sh` | Rollback to previous deployment |

### Utility Scripts

| Script | Description |
|--------|-------------|
| `aws-auth.sh` | Configure AWS authentication |
| `check-cluster-health.sh` | Verify cluster health before deployment |
| `install-monitoring.sh` | Install Prometheus, Grafana, Loki stack |
| `kubectl-port-forward-grafana.sh` | Access Grafana locally |

## Usage

### First-time Setup

```bash
# Make scripts executable
chmod +x *.sh

# Configure AWS authentication
./aws-auth.sh stage
```

### Deploy to Stage

```bash
./deploy-stage.sh v1.0.0
```

### Deploy to Production

```bash
./deploy-prod.sh v1.0.0
```

### Rollback

```bash
# Rollback to previous version
./rollback.sh

# Rollback to specific revision
./rollback.sh 5
```

### Access Grafana

```bash
./kubectl-port-forward-grafana.sh
# Open http://localhost:3000
```

## Prerequisites

- AWS CLI v2
- kubectl
- Helm 3.13+
- jq (for some scripts)

## Environment Variables

| Variable | Description |
|----------|-------------|
| `AWS_PROFILE` | AWS profile to use |
| `AWS_REGION` | AWS region (default: eu-central-1) |
| `KUBECONFIG` | Path to kubeconfig file |

## Best Practices

1. Always run `check-cluster-health.sh` before production deployments
2. Test changes on stage before deploying to production
3. Keep track of deployment revisions for easy rollback
4. Monitor Grafana during and after deployments

