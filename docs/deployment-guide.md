# Detailed Deployment Guide

## Prerequisites Checklist

- [ ] AWS Account with required permissions
- [ ] Domain registered in Route53
- [ ] SSH key pair generated
- [ ] Required tools installed:
  - kubectl
  - helm
  - aws-cli
  - terraform
  - ansible

## Step-by-Step Deployment

### 1. Initial Setup

```bash
# Clone repository
git clone https://github.com/your-org/kubernetes-ha-platform.git
cd kubernetes-ha-platform

# Create configuration
cp config.example.yaml config.yaml
# Edit config.yaml with your values
```

### 2. Infrastructure Deployment

```bash
# Initialize Terraform
cd terraform
terraform init

# Review plan
terraform plan -out=tfplan

# Apply infrastructure
terraform apply tfplan
```

### 3. Cluster Configuration

```bash
# Update kubeconfig
aws eks update-kubeconfig --name cluster-name --region us-west-2

# Verify cluster access
kubectl cluster-info
```

### 4. Security Implementation

```bash
# Apply security policies
kubectl apply -f kubernetes/security/

# Verify policies
kubectl get psp
kubectl get networkpolicies --all-namespaces
```

### 5. Monitoring Stack Deployment

```bash
# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Deploy monitoring stack
helm install monitoring prometheus-community/kube-prometheus-stack -f kubernetes/monitoring/values.yaml

# Verify deployment
kubectl get pods -n monitoring
```

### 6. Application Deployment

```bash
# Deploy applications using Helmsman
helmsman -f helmsman.yaml --apply
```

## Verification Steps

1. Check cluster health:
```bash
kubectl get nodes
kubectl get pods --all-namespaces
```

2. Verify monitoring:
- Access Grafana: https://grafana.mecan.ata.tips
- Check Prometheus targets
- Verify alert rules

3. Test security policies:
```bash
# Try to create privileged pod (should fail)
kubectl apply -f test/privileged-pod.yaml
```

4. Validate backups:
```bash
velero backup list
```

3. **Troubleshooting Guide**

```markdown:docs/troubleshooting.md
# Troubleshooting Guide

## Common Issues and Solutions

### 1. Node Issues

#### Node Not Ready
```bash
# Check node conditions
kubectl describe node <node-name>

# Check kubelet logs
journalctl -u kubelet -n 100

# Common solutions:
- Verify network connectivity
- Check kubelet service status
- Validate node resources
```

#### High Resource Usage
```bash
# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces

# Solutions:
- Scale resources
- Review resource limits
- Check for resource leaks
```

### 2. Pod Issues

#### Pod in CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n <namespace>
kubectl describe pod <pod-name> -n <namespace>

# Common solutions:
- Check configuration
- Verify secrets/configmaps
- Review resource limits
```

#### Pod Stuck in Pending
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Common reasons:
- Resource constraints
- Node selector issues
- PVC binding issues
```

### 3. Networking Issues

#### Service Connectivity
```bash
# Debug service
kubectl get endpoints <service-name>
kubectl describe service <service-name>

# Test connectivity
kubectl run test-pod --image=busybox -- sleep 3600
kubectl exec -it test-pod -- wget -O- http://service-name:port
```

#### Ingress Issues
```bash
# Check ingress status
kubectl describe ingress <ingress-name>

# Verify TLS
openssl s_client -connect domain:443 -servername domain

# Common solutions:
- Check DNS records
- Verify certificate status
- Review ingress controller logs
```

### 4. Monitoring Issues

#### Prometheus Target Down
```bash
# Check service monitor
kubectl get servicemonitor -n monitoring

# Verify endpoints
kubectl get endpoints -n monitoring

# Solutions:
- Check label selectors
- Verify port configurations
- Review target accessibility
```

#### Grafana Dashboard Issues
```bash
# Verify datasource connection
kubectl port-forward svc/prometheus-operated 9090:9090 -n monitoring
curl localhost:9090/-/healthy

# Check Grafana logs
kubectl logs -l app=grafana -n monitoring
```

### 5. Security Issues

#### Policy Violations
```bash
# Check policy status
kubectl describe psp <policy-name>
kubectl get events --field-selector reason=FailedCreate

# Review violations
kubectl logs -n gatekeeper-system -l control-plane=controller-manager
```

### 6. Backup/Restore Issues

#### Failed Backups
```bash
# Check Velero logs
kubectl logs deployment/velero -n velero

# Verify S3 access
aws s3 ls s3://backup-bucket

# Solutions:
- Check AWS credentials
- Verify permissions
- Review backup configuration
```

## Diagnostic Commands

### Cluster Health Check
```bash
#!/bin/bash
# Save as cluster-health.sh

echo "Checking cluster components..."
kubectl get componentstatuses

echo "Checking nodes..."
kubectl get nodes -o wide

echo "Checking pod status..."
kubectl get pods --all-namespaces | grep -v Running

echo "Checking system pods..."
kubectl get pods -n kube-system

echo "Checking persistent volumes..."
kubectl get pv,pvc --all-namespaces

echo "Checking certificate status..."
kubectl get certificates,certificaterequests --all-namespaces
```

### Network Diagnostics
```bash
#!/bin/bash
# Save as network-diagnostics.sh

echo "Checking CoreDNS..."
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

echo "Checking ingress controller..."
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

echo "Checking network policies..."
kubectl get networkpolicies --all-namespaces
```

## Emergency Procedures

### 1. Control Plane Recovery
```bash
# Check etcd health
kubectl exec -it etcd-pod -n kube-system -- etcdctl member list

# Restore from backup if needed
velero restore create --from-backup latest-backup --wait
```

### 2. Node Recovery
```bash
# Drain node
kubectl drain <node-name> --ignore-daemonsets

# Perform maintenance

# Uncordon node
kubectl uncordon <node-name>
```

### 3. Data Recovery
```bash
# List available backups
velero backup get

# Restore specific namespace
velero restore create --from-backup <backup-name> --include-namespaces <namespace>
```
```

Would you like me to continue with:
1. Advanced networking configurations (service mesh, CNI settings)
2. Automated testing procedures
3. Performance tuning guidelines
4. Compliance and audit procedures?

Let me know which aspects you'd like to see next! 