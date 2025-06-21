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