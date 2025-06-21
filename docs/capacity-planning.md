# Capacity Planning Guidelines

## 1. Resource Calculation

### Node Capacity Planning
```bash
# Calculate required nodes
TOTAL_CPU_REQUEST=<sum of all pod CPU requests>
TOTAL_MEM_REQUEST=<sum of all pod memory requests>
NODE_CPU_CAPACITY=<CPU cores per node>
NODE_MEM_CAPACITY=<Memory per node>

MIN_NODES=$((($TOTAL_CPU_REQUEST / $NODE_CPU_CAPACITY) + 1))
```

### Storage Planning
```yaml
# Example storage class with different tiers
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iopsPerGB: "3000"
  throughput: "125"
```

## 2. Scaling Thresholds

### Horizontal Pod Autoscaling
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

## 3. Growth Planning

### Cluster Expansion Checklist
1. Monitor current usage trends
2. Project growth for next 6 months
3. Plan node pool expansions
4. Update networking configurations
5. Adjust backup storage capacity 