# Performance Tuning Guidelines

## 1. Node-Level Tuning

### System Settings
```bash
# Add to /etc/sysctl.conf
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
vm.max_map_count = 262144
```

### Container Runtime Settings
```json
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
```

## 2. Kubernetes Settings

### API Server
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
spec:
  containers:
  - command:
    - kube-apiserver
    - --max-requests-inflight=1500
    - --max-mutating-requests-inflight=500
    - --request-timeout=300s
```

### Scheduler
```yaml
apiVersion: kubescheduler.config.k8s.io/v1beta1
kind: KubeSchedulerConfiguration
profiles:
- schedulerName: default-scheduler
  plugins:
    score:
      disabled:
      - name: NodeResourcesLeastAllocated
      enabled:
      - name: NodeResourcesMostAllocated
```

## 3. Resource Management

### Pod Resource Requests/Limits
```yaml
resources:
  requests:
    cpu: 100m
    memory: 256Mi
  limits:
    cpu: 200m
    memory: 512Mi
```

### Horizontal Pod Autoscaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 4. Monitoring and Optimization

### Prometheus Rules
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: performance-alerts
spec:
  groups:
  - name: performance
    rules:
    - alert: HighCPUUsage
      expr: node_cpu_usage_percentage > 80
      for: 5m
    - alert: HighMemoryUsage
      expr: node_memory_usage_percentage > 85
      for: 5m
```

3. **Compliance and Audit Procedures**

```yaml:kubernetes/compliance/audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  resources:
  - group: ""
    resources: ["pods", "services"]
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  omitStages:
  - RequestReceived
- level: Request
  users: ["system:admin"]
  resources:
  - group: ""
    resources: ["pods/exec", "pods/attach"]
```

```bash:scripts/compliance-check.sh
#!/bin/bash

# Compliance and audit check script
REPORT_DIR="./reports/compliance"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="${REPORT_DIR}/compliance-report-${TIMESTAMP}.txt"

mkdir -p "$REPORT_DIR"

check_cis_benchmarks() {
    echo "Running CIS Benchmark checks..."
    
    # Run kube-bench
    kube-bench run --check-type="master,node" > "${REPORT_DIR}/cis-report.txt"
    
    # Parse results
    local failed_tests=$(grep "\[FAIL\]" "${REPORT_DIR}/cis-report.txt" | wc -l)
    echo "Failed CIS tests: $failed_tests"
    
    return $failed_tests
}

check_pod_security() {
    echo "Checking Pod Security Standards..."
    
    # Check for privileged containers
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.containers[].securityContext.privileged == true)'
    
    # Check for host path volumes
    kubectl get pods --all-namespaces -o json | jq -r '.items[] | select(.spec.volumes[].hostPath)'
}

check_network_policies() {
    echo "Validating Network Policies..."
    
    # Check default deny policies
    kubectl get networkpolicies --all-namespaces
    
    # Check for unprotected namespaces
    kubectl get ns -o json | jq -r '.items[] | select(.metadata.annotations."net.beta.kubernetes.io/network-policy" == null) | .metadata.name'
}

check_rbac_compliance() {
    echo "Auditing RBAC configurations..."
    
    # Check cluster roles
    kubectl get clusterroles
    
    # Check role bindings
    kubectl get rolebindings --all-namespaces
    
    # Check service accounts
    kubectl get serviceaccounts --all-namespaces
}

generate_compliance_report() {
    {
        echo "Compliance Report - $(date)"
        echo "======================="
        echo
        echo "1. CIS Benchmark Results"
        cat "${REPORT_DIR}/cis-report.txt"
        echo
        echo "2. Pod Security Violations"
        check_pod_security
        echo
        echo "3. Network Policy Status"
        check_network_policies
        echo
        echo "4. RBAC Audit Results"
        check_rbac_compliance
    } > "$REPORT_FILE"
}

check_audit_logs() {
    echo "Checking audit logs..."
    
    # Check API server audit logs
    kubectl logs -n kube-system -l component=kube-apiserver | grep "audit"
    
    # Check for suspicious activities
    kubectl logs -n kube-system -l component=kube-apiserver | grep -i "forbidden\|unauthorized"
}

main() {
    echo "Starting compliance checks at $(date)"
    
    check_cis_benchmarks
    check_pod_security
    check_network_policies
    check_rbac_compliance
    check_audit_logs
    
    generate_compliance_report
    
    echo "Compliance check completed. Report available at $REPORT_FILE"
}

main 