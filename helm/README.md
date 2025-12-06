# OneThought Helm Chart

## Overview

This Helm chart deploys the OneThought application on Kubernetes with the following components:

- **Frontend**: Next.js SSR application
- **Backend**: Optional separate API service
- **Ingress**: AWS ALB Ingress Controller
- **Autoscaling**: Horizontal Pod Autoscaler
- **Security**: Network Policies, Pod Disruption Budgets
- **Monitoring**: ServiceMonitor for Prometheus

## Prerequisites

- Kubernetes 1.28+
- Helm 3.13+
- AWS Load Balancer Controller installed
- External Secrets Operator (for AWS Secrets Manager integration)
- Prometheus Operator (for ServiceMonitor)

## Installation

### Stage Environment

```bash
helm upgrade --install onethought ./onethought \
  -n onethought \
  --create-namespace \
  -f onethought/values.stage.yaml \
  --set frontend.image.repository=123456789.dkr.ecr.eu-central-1.amazonaws.com/onethought-stage-frontend \
  --set frontend.image.tag=v1.0.0
```

### Production Environment

```bash
helm upgrade --install onethought ./onethought \
  -n onethought \
  --create-namespace \
  -f onethought/values.prod.yaml \
  --set frontend.image.repository=123456789.dkr.ecr.eu-central-1.amazonaws.com/onethought-prod-frontend \
  --set frontend.image.tag=v1.0.0
```

## Configuration

### Key Values

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.environment` | Environment name | `stage` |
| `global.domain` | Application domain | `onethought.app` |
| `frontend.enabled` | Enable frontend deployment | `true` |
| `frontend.replicaCount` | Initial replica count | `2` |
| `frontend.autoscaling.enabled` | Enable HPA | `true` |
| `backend.enabled` | Enable separate backend | `false` |
| `ingress.enabled` | Enable Ingress | `true` |
| `secrets.useExternalSecrets` | Use AWS Secrets Manager | `true` |

### External Secrets

The chart integrates with AWS Secrets Manager through External Secrets Operator:

```yaml
secrets:
  useExternalSecrets: true
  externalSecrets:
    enabled: true
    secretStoreRef:
      name: aws-secrets-manager
      kind: ClusterSecretStore
    data:
      - secretKey: SUPABASE_URL
        remoteRef:
          key: onethought-stage/app-secrets
          property: SUPABASE_URL
```

## Upgrading

```bash
# Check what will change
helm diff upgrade onethought ./onethought -f onethought/values.stage.yaml

# Apply upgrade
helm upgrade onethought ./onethought -f onethought/values.stage.yaml
```

## Rollback

```bash
# List revisions
helm history onethought -n onethought

# Rollback to previous version
helm rollback onethought -n onethought

# Rollback to specific version
helm rollback onethought 5 -n onethought
```

## Uninstalling

```bash
helm uninstall onethought -n onethought
```

## Development

### Lint Chart

```bash
helm lint ./onethought
```

### Template Rendering

```bash
helm template onethought ./onethought -f onethought/values.stage.yaml
```

### Package Chart

```bash
helm package ./onethought
```

