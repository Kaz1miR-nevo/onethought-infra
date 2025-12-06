# Monitoring Stack

## Overview

This directory contains Kubernetes manifests and Helm values for the monitoring stack:

- **Prometheus** - Metrics collection and alerting
- **Grafana** - Visualization and dashboards
- **Loki** - Log aggregation
- **Promtail** - Log collection agent

## Components

### Prometheus Stack (kube-prometheus-stack)

Includes:
- Prometheus Operator
- Prometheus
- Alertmanager
- Grafana
- Node Exporter
- Kube State Metrics

### Loki Stack

Includes:
- Loki (log storage)
- Promtail (log collection)

## Installation

The monitoring stack is installed via Terraform in the `grafana-loki.tf` file. For manual installation:

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus stack
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring --create-namespace \
  -f prometheus-values.yaml

# Install Loki
helm upgrade --install loki grafana/loki \
  -n monitoring \
  -f loki-values.yaml

# Install Promtail
helm upgrade --install promtail grafana/promtail \
  -n monitoring \
  -f promtail-values.yaml
```

## Accessing Grafana

### Port Forward

```bash
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

### Default Credentials

- **Username**: admin
- **Password**: Set via Terraform or Helm values

## Dashboards

Pre-configured dashboards include:

1. **Kubernetes Cluster Overview** - Node and cluster metrics
2. **Kubernetes Pods** - Pod-level metrics
3. **Node Exporter** - Host-level metrics
4. **OneThought Application** - Custom application metrics (imported)

### Custom Dashboards

To add custom dashboards:

1. Create the dashboard in Grafana
2. Export as JSON
3. Add to `dashboards/` directory
4. Update Helm values to include the dashboard

## Alerting

Alertmanager is configured with basic rules. Configure notifications:

```yaml
alertmanager:
  config:
    receivers:
      - name: 'slack'
        slack_configs:
          - api_url: 'https://hooks.slack.com/services/xxx'
            channel: '#alerts'
```

## Log Queries

### Loki Query Examples

```logql
# All logs from onethought namespace
{namespace="onethought"}

# Error logs only
{namespace="onethought"} |= "error"

# JSON logs with level filter
{namespace="onethought"} | json | level="error"

# Logs from specific pod
{namespace="onethought", pod=~"frontend.*"}
```

## Troubleshooting

### Prometheus not scraping targets

```bash
kubectl get servicemonitors -n onethought
kubectl describe servicemonitor <name> -n onethought
```

### Loki not receiving logs

```bash
kubectl logs -l app.kubernetes.io/name=promtail -n monitoring
```

### Grafana datasource issues

```bash
kubectl logs -l app.kubernetes.io/name=grafana -n monitoring
```

