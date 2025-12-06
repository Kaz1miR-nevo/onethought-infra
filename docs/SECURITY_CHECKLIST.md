# OneThought Security Checklist

## Pre-Deployment Security Checklist

Complete this checklist before deploying to production.

### Infrastructure Security

- [ ] **VPC Configuration**
  - [ ] Private subnets for EKS nodes
  - [ ] NAT gateways for outbound traffic
  - [ ] VPC Flow Logs enabled
  - [ ] No public IPs on worker nodes

- [ ] **EKS Security**
  - [ ] Cluster endpoint private access enabled
  - [ ] OIDC provider configured
  - [ ] Secrets encryption with KMS
  - [ ] Control plane logging enabled

- [ ] **IAM**
  - [ ] Least privilege policies
  - [ ] IRSA for pod-level permissions
  - [ ] No hardcoded credentials
  - [ ] OIDC for GitHub Actions

- [ ] **Network Policies**
  - [ ] Network policies deployed
  - [ ] Pod-to-pod communication restricted
  - [ ] Egress limited to required services

### Application Security

- [ ] **Secrets Management**
  - [ ] Secrets in AWS Secrets Manager
  - [ ] No secrets in code or environment files
  - [ ] External Secrets Operator configured
  - [ ] Secret rotation policy defined

- [ ] **Authentication & Authorization**
  - [ ] JWT tokens properly validated
  - [ ] Token expiration configured
  - [ ] Supabase RLS policies verified
  - [ ] Admin endpoints protected

- [ ] **Input Validation**
  - [ ] All user inputs validated
  - [ ] Zod schemas for API routes
  - [ ] SQL injection prevention (Supabase RLS)
  - [ ] XSS prevention (React default escaping)

- [ ] **Headers & Cookies**
  - [ ] HTTPS enforced
  - [ ] HSTS header configured
  - [ ] CSP header configured
  - [ ] Secure cookie flags set

### Container Security

- [ ] **Docker Image**
  - [ ] Non-root user
  - [ ] Multi-stage build
  - [ ] No sensitive data in layers
  - [ ] Image vulnerability scanning enabled

- [ ] **Pod Security**
  - [ ] Read-only root filesystem (where possible)
  - [ ] Privilege escalation disabled
  - [ ] Capabilities dropped
  - [ ] Resource limits set

### WAF & DDoS Protection

- [ ] **AWS WAF**
  - [ ] WAF WebACL attached to ALB
  - [ ] Rate limiting configured
  - [ ] SQL injection rules enabled
  - [ ] Known bad inputs blocked

- [ ] **DDoS Mitigation**
  - [ ] AWS Shield Standard (automatic)
  - [ ] Consider Shield Advanced for production
  - [ ] CloudFront consideration for static assets

### Monitoring & Alerting

- [ ] **Logging**
  - [ ] Application logs to Loki
  - [ ] Audit logs enabled
  - [ ] Log retention configured
  - [ ] Sensitive data not logged

- [ ] **Monitoring**
  - [ ] Prometheus metrics collected
  - [ ] Grafana dashboards configured
  - [ ] Health check endpoints working
  - [ ] Alertmanager rules defined

### CI/CD Security

- [ ] **Pipeline Security**
  - [ ] OIDC authentication (no static credentials)
  - [ ] Secrets not exposed in logs
  - [ ] Dependency scanning in pipeline
  - [ ] Container image scanning

- [ ] **Deployment Security**
  - [ ] Manual approval for production
  - [ ] Rollback capability tested
  - [ ] Blue-green or canary capability
  - [ ] Audit trail for deployments

## Security Best Practices

### What to NEVER Do

❌ Commit secrets to git
❌ Use hardcoded credentials
❌ Disable RLS in production
❌ Run containers as root
❌ Expose debug endpoints in production
❌ Store PII without encryption
❌ Skip security headers

### What to ALWAYS Do

✅ Use environment variables for config
✅ Encrypt data at rest and in transit
✅ Apply principle of least privilege
✅ Log security-relevant events
✅ Keep dependencies updated
✅ Review security before deployment
✅ Test rollback procedures

## Security Response Procedures

### If Credentials Are Exposed

1. **Immediately**:
   - Rotate all exposed credentials
   - Review access logs for unauthorized use
   - Notify security team

2. **Short-term**:
   - Audit all systems using those credentials
   - Enable additional monitoring
   - Document incident

3. **Long-term**:
   - Improve secret management
   - Add detection mechanisms
   - Update training/documentation

### If Attack Detected

1. **Assess**:
   - Identify type of attack
   - Determine scope of impact
   - Check for data exfiltration

2. **Respond**:
   - Block malicious IPs (WAF)
   - Enable heightened monitoring
   - Preserve evidence (logs)

3. **Recover**:
   - Restore from clean backups if needed
   - Patch vulnerabilities
   - Post-incident review

## Compliance Considerations

### GDPR

- [ ] User data deletion capability
- [ ] Data export capability
- [ ] Privacy policy updated
- [ ] Cookie consent implemented

### SOC 2

- [ ] Access logging
- [ ] Change management documented
- [ ] Incident response plan
- [ ] Regular security assessments

## Regular Security Tasks

### Weekly

- [ ] Review security alerts
- [ ] Check for failed login attempts
- [ ] Review WAF blocked requests

### Monthly

- [ ] Dependency vulnerability scan
- [ ] Review IAM permissions
- [ ] Check certificate expiration
- [ ] Review access logs

### Quarterly

- [ ] Penetration testing
- [ ] Security training review
- [ ] Disaster recovery test
- [ ] Policy review

