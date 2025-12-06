# Pre-Production Health Checklist

## Before Going Live

Complete this checklist before enabling production traffic.

### Infrastructure

- [ ] **EKS Cluster**
  - [ ] All nodes Ready
  - [ ] No nodes with pressure conditions
  - [ ] Cluster Autoscaler functioning
  - [ ] Correct Kubernetes version

- [ ] **Networking**
  - [ ] ALB created and healthy
  - [ ] Target groups show healthy targets
  - [ ] SSL certificate valid and not expiring soon
  - [ ] DNS records configured

- [ ] **Storage**
  - [ ] EBS CSI driver working
  - [ ] PVCs bound successfully
  - [ ] S3 buckets accessible

### Application

- [ ] **Deployments**
  - [ ] All pods Running
  - [ ] Correct replica count
  - [ ] Recent deployment successful
  - [ ] No pending rollouts

- [ ] **Health Checks**
  - [ ] Liveness probes passing
  - [ ] Readiness probes passing
  - [ ] Health endpoint returning 200

- [ ] **Configuration**
  - [ ] Environment variables set
  - [ ] Secrets synced from AWS
  - [ ] ConfigMaps applied

### Security

- [ ] **WAF**
  - [ ] WebACL attached to ALB
  - [ ] Rate limiting configured
  - [ ] Managed rules enabled

- [ ] **Network Policies**
  - [ ] Policies applied
  - [ ] Ingress restricted
  - [ ] Egress limited

- [ ] **Secrets**
  - [ ] All secrets populated
  - [ ] No placeholder values
  - [ ] Rotation schedule defined

### Monitoring

- [ ] **Prometheus**
  - [ ] Scraping application metrics
  - [ ] Alerting rules configured
  - [ ] No firing alerts (except expected)

- [ ] **Grafana**
  - [ ] Dashboards loading
  - [ ] Data sources connected
  - [ ] Admin password changed

- [ ] **Loki**
  - [ ] Logs ingesting
  - [ ] Retention configured
  - [ ] Query performance acceptable

### Backup & Recovery

- [ ] **State**
  - [ ] Terraform state backed up
  - [ ] Helm release history available

- [ ] **Rollback**
  - [ ] Rollback tested
  - [ ] Previous versions available
  - [ ] Rollback time acceptable

### Documentation

- [ ] **Runbooks**
  - [ ] Deployment guide complete
  - [ ] Troubleshooting guide complete
  - [ ] Incident response plan

- [ ] **Access**
  - [ ] Team has kubectl access
  - [ ] AWS access configured
  - [ ] Grafana access provided

## Go-Live Verification

After enabling traffic:

1. **Smoke Tests**
   - [ ] Homepage loads
   - [ ] Login works
   - [ ] Core features functional
   - [ ] API responses correct

2. **Performance**
   - [ ] Response times acceptable
   - [ ] No error spike in logs
   - [ ] CPU/Memory within limits

3. **Monitoring**
   - [ ] Grafana shows traffic
   - [ ] Logs flowing
   - [ ] Alerts not firing

## Post-Launch

Within 24 hours:

- [ ] Monitor error rates
- [ ] Review performance metrics
- [ ] Check resource utilization
- [ ] Gather user feedback
- [ ] Document any issues

## Warning: Do NOT Touch in Production

⛔ **Never modify directly in production:**

1. **Database**
   - No direct SQL against production
   - RLS policies must not be disabled
   - Migrations through proper channels only

2. **Secrets**
   - No manual secret rotation without documentation
   - Coordinate key rotations

3. **Terraform**
   - No `terraform apply` without review
   - No manual resource modifications

4. **Kubernetes**
   - No `kubectl delete` on critical resources
   - No manual pod deletions during incidents

## Emergency Contacts

| Role | Name | Contact |
|------|------|---------|
| DevOps Lead | TBD | TBD |
| Backend Lead | TBD | TBD |
| On-call | TBD | TBD |

## Rollback Procedure

If issues detected:

```bash
# 1. Assess severity
# Is this affecting users? Is data at risk?

# 2. Quick rollback
cd infra/scripts
./rollback.sh

# 3. Verify rollback
kubectl get pods -n onethought
kubectl logs -l app.kubernetes.io/component=frontend -n onethought

# 4. Monitor
# Check Grafana for error rates

# 5. Investigate
# Review logs, identify root cause

# 6. Document
# Create incident report
```

