#!/bin/bash

# Cluster validation script
LOGFILE="/var/log/cluster-validation.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

check_kubernetes_components() {
    echo "Checking Kubernetes components..."
    
    # Check control plane components
    for component in api-server controller-manager scheduler; do
        if ! kubectl get componentstatuses cs-${component} | grep -q "Healthy"; then
            echo "ERROR: ${component} is not healthy"
            return 1
        fi
    done
    
    # Check nodes
    if [ $(kubectl get nodes --no-headers | grep -c "Ready") -lt 6 ]; then
        echo "ERROR: Not all nodes are ready"
        return 1
    fi
    
    return 0
}

check_monitoring_stack() {
    echo "Checking monitoring stack..."
    
    # Check Prometheus
    if ! kubectl -n monitoring get pods -l app=prometheus | grep -q "Running"; then
        echo "ERROR: Prometheus is not running"
        return 1
    fi
    
    # Check Grafana
    if ! kubectl -n monitoring get pods -l app=grafana | grep -q "Running"; then
        echo "ERROR: Grafana is not running"
        return 1
    fi
    
    # Check Loki
    if ! kubectl -n monitoring get pods -l app=loki | grep -q "Running"; then
        echo "ERROR: Loki is not running"
        return 1
    fi
    
    return 0
}

check_security_compliance() {
    echo "Checking security compliance..."
    
    # Run Kube-bench
    if ! kube-bench run --check-type="master,node" > /tmp/kube-bench.txt; then
        echo "ERROR: Kube-bench checks failed"
        return 1
    fi
    
    # Run Trivy
    if ! trivy k8s --report summary cluster > /tmp/trivy-report.txt; then
        echo "ERROR: Trivy security scan failed"
        return 1
    fi
    
    return 0
}

check_applications() {
    echo "Checking applications..."
    
    # Check MongoDB
    if ! kubectl -n storage get statefulset mongodb | grep -q "3/3"; then
        echo "ERROR: MongoDB cluster is not fully ready"
        return 1
    fi
    
    # Check Kafka
    if ! kubectl -n storage get statefulset kafka | grep -q "3/3"; then
        echo "ERROR: Kafka cluster is not fully ready"
        return 1
    fi
    
    return 0
}

generate_report() {
    local report_file="/reports/validation-$(date +%Y%m%d).txt"
    
    echo "Generating validation report..."
    {
        echo "Cluster Validation Report - $(date)"
        echo "================================="
        echo
        echo "Kubernetes Components Status:"
        kubectl get componentstatuses
        echo
        echo "Node Status:"
        kubectl get nodes
        echo
        echo "Security Scan Results:"
        cat /tmp/kube-bench.txt
        echo
        cat /tmp/trivy-report.txt
        echo
        echo "Application Status:"
        kubectl get pods --all-namespaces
    } > "$report_file"
    
    echo "Report generated: $report_file"
}

main() {
    echo "Starting cluster validation at $(date)"
    
    local failed=0
    
    check_kubernetes_components || failed=1
    check_monitoring_stack || failed=1
    check_security_compliance || failed=1
    check_applications || failed=1
    
    generate_report
    
    if [ $failed -eq 1 ]; then
        echo "Validation failed. Check the report for details."
        exit 1
    else
        echo "Validation successful!"
        exit 0
    fi
}

main 