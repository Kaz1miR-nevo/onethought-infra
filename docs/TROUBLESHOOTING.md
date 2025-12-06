# Troubleshooting Guide

## Common Issues and Solutions

### Deployment Issues

#### Pods stuck in Pending state

**Symptoms:**
```bash
kubectl get pods -n onethought
# Shows pods in "Pending" status
```

**Causes & Solutions:**

1. **Insufficient resources**
   ```bash
   # Check node resources
   kubectl describe nodes | grep -A5 "Allocated resources"
   
   # Solution: Scale up nodes or reduce resource requests
   ```

2. **No available nodes match pod requirements**
   ```bash
   # Check pod events
   kubectl describe pod <pod-name> -n onethought
   
   # Look for scheduling errors
   ```

3. **PVC not bound**
   ```bash
   kubectl get pvc -n onethought
   # Check if PVCs are in "Pending" state
   ```

#### Pods in CrashLoopBackOff

**Symptoms:**
```bash
kubectl get pods -n onethought
# Shows "CrashLoopBackOff" status
```

**Solutions:**

1. **Check logs**
   ```bash
   kubectl logs <pod-name> -n onethought
   kubectl logs <pod-name> -n onethought --previous
   ```

2. **Check environment variables**
   ```bash
   kubectl describe pod <pod-name> -n onethought
   # Look at Environment section
   ```

3. **Check secrets**
   ```bash
   kubectl get externalsecrets -n onethought
   kubectl describe externalsecret <name> -n onethought
   ```

#### ImagePullBackOff

**Symptoms:**
```bash
kubectl get pods -n onethought
# Shows "ImagePullBackOff" or "ErrImagePull"
```

**Solutions:**

1. **Verify image exists**
   ```bash
   aws ecr describe-images --repository-name onethought-stage-frontend
   ```

2. **Check ECR permissions**
   ```bash
   # Node role should have ECR access
   aws iam get-role-policy --role-name <node-role-name> --policy-name AmazonEC2ContainerRegistryReadOnly
   ```

3. **Verify image URL**
   ```bash
   kubectl describe pod <pod-name> -n onethought | grep Image
   ```

### Ingress Issues

#### ALB not created

**Symptoms:**
- Ingress shows no address
- ALB not visible in AWS Console

**Solutions:**

1. **Check ALB Controller**
   ```bash
   kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
   ```

2. **Verify ingress annotations**
   ```bash
   kubectl describe ingress onethought -n onethought
   # Check for correct ALB annotations
   ```

3. **Check subnet tags**
   - Subnets must have `kubernetes.io/role/elb` tag

#### 502 Bad Gateway

**Symptoms:**
- ALB returns 502 error

**Solutions:**

1. **Check target health**
   ```bash
   # In AWS Console, check ALB Target Groups
   # Verify targets are healthy
   ```

2. **Verify health check endpoint**
   ```bash
   kubectl exec -it <pod-name> -n onethought -- wget -qO- http://localhost:3000/api/health
   ```

3. **Check security groups**
   - ALB must be able to reach pods

### Secrets Issues

#### External Secrets not syncing

**Symptoms:**
```bash
kubectl get externalsecrets -n onethought
# Shows "SecretSyncedError"
```

**Solutions:**

1. **Check ClusterSecretStore**
   ```bash
   kubectl get clustersecretstores
   kubectl describe clustersecretstore aws-secrets-manager
   ```

2. **Verify IAM role**
   ```bash
   # Check service account annotation
   kubectl get sa -n external-secrets external-secrets -o yaml
   ```

3. **Check secret exists in AWS**
   ```bash
   aws secretsmanager get-secret-value --secret-id onethought-stage/app-secrets
   ```

### Monitoring Issues

#### Grafana not showing data

**Solutions:**

1. **Check Prometheus**
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus
   kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring
   # Open http://localhost:9090 and check targets
   ```

2. **Check ServiceMonitor**
   ```bash
   kubectl get servicemonitors -n onethought
   kubectl describe servicemonitor <name> -n onethought
   ```

3. **Check Grafana datasource**
   - In Grafana UI, go to Configuration → Data Sources
   - Test the Prometheus connection

#### Logs not appearing in Loki

**Solutions:**

1. **Check Promtail**
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=promtail
   kubectl logs -n monitoring -l app.kubernetes.io/name=promtail
   ```

2. **Check Loki**
   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=loki
   kubectl logs -n monitoring -l app.kubernetes.io/name=loki
   ```

3. **Verify S3 permissions** (for Loki storage)

### Terraform Issues

#### State lock error

**Symptoms:**
```
Error: Error locking state
```

**Solutions:**

```bash
# If you're sure no one else is running Terraform:
terraform force-unlock <LOCK_ID>
```

#### Resource already exists

**Solutions:**

```bash
# Import existing resource
terraform import <resource_type>.<name> <resource_id>
```

### Network Issues

#### Pods can't reach external services

**Solutions:**

1. **Check NAT Gateway**
   ```bash
   # In AWS Console, verify NAT Gateway is active
   ```

2. **Check Network Policy**
   ```bash
   kubectl get networkpolicies -n onethought
   kubectl describe networkpolicy <name> -n onethought
   ```

3. **Test from pod**
   ```bash
   kubectl exec -it <pod-name> -n onethought -- wget -qO- https://example.com
   ```

### Performance Issues

#### High CPU/Memory usage

**Solutions:**

1. **Check resource usage**
   ```bash
   kubectl top pods -n onethought
   kubectl top nodes
   ```

2. **Review HPA status**
   ```bash
   kubectl get hpa -n onethought
   kubectl describe hpa onethought-frontend -n onethought
   ```

3. **Check for memory leaks**
   - Review Grafana memory dashboards
   - Check for trending increases

## Useful Commands

### Quick Diagnostics

```bash
# Cluster overview
kubectl get all -n onethought

# Pod details
kubectl describe pod <pod-name> -n onethought

# Recent events
kubectl get events -n onethought --sort-by='.lastTimestamp'

# Logs (last 100 lines)
kubectl logs -l app.kubernetes.io/component=frontend -n onethought --tail=100

# Resource usage
kubectl top pods -n onethought

# Check Helm release
helm status onethought -n onethought
helm history onethought -n onethought
```

### Emergency Procedures

```bash
# Quick rollback
helm rollback onethought -n onethought

# Force delete stuck pods
kubectl delete pod <pod-name> -n onethought --force --grace-period=0

# Restart deployment
kubectl rollout restart deployment/onethought-frontend -n onethought
```

## Getting Help

1. Check this troubleshooting guide
2. Review Grafana dashboards and logs
3. Check AWS Console for infrastructure issues
4. Contact the DevOps team with:
   - Error messages
   - Relevant logs
   - Steps to reproduce

