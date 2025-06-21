#!/bin/bash

# Automated test runner script
set -e

LOG_DIR="./reports/tests"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
TEST_REPORT="${LOG_DIR}/test-report-${TIMESTAMP}.txt"

mkdir -p "$LOG_DIR"

# Test Categories
declare -A test_categories=(
    ["cluster"]="test_cluster_health"
    ["security"]="test_security"
    ["performance"]="test_performance"
    ["applications"]="test_applications"
)

test_cluster_health() {
    echo "Testing cluster health..."
    
    # Check nodes
    if ! kubectl get nodes | grep -q "Ready"; then
        return 1
    fi
    
    # Check control plane
    if ! kubectl get componentstatuses | grep -q "Healthy"; then
        return 1
    fi
    
    # Check core DNS
    if ! kubectl get pods -n kube-system -l k8s-app=kube-dns | grep -q "Running"; then
        return 1
    fi
    
    return 0
}

test_security() {
    echo "Testing security configurations..."
    
    # Test network policies
    if ! kubectl get networkpolicies --all-namespaces; then
        return 1
    fi
    
    # Test pod security policies
    if ! kubectl auth can-i use podsecuritypolicy/restricted; then
        return 1
    fi
    
    # Test RBAC
    if ! kubectl auth can-i --list; then
        return 1
    fi
    
    return 0
}

test_performance() {
    echo "Running performance tests..."
    
    # Test API response time
    if ! curl -k -s -o /dev/null -w "%{http_code}" https://kubernetes.default.svc > /dev/null; then
        return 1
    fi
    
    # Test pod startup time
    kubectl run test-pod --image=nginx --rm -it --restart=Never > /dev/null
    
    return 0
}

test_applications() {
    echo "Testing application deployments..."
    
    # Test monitoring stack
    if ! kubectl get pods -n monitoring | grep -q "Running"; then
        return 1
    fi
    
    # Test ingress
    if ! curl -k -s -o /dev/null -w "%{http_code}" https://grafana.mecan.ata.tips > /dev/null; then
        return 1
    fi
    
    return 0
}

run_tests() {
    local category=$1
    local test_function=${test_categories[$category]}
    
    echo "Running $category tests..."
    if $test_function; then
        echo "✅ $category tests passed"
        return 0
    else
        echo "❌ $category tests failed"
        return 1
    fi
}

generate_report() {
    {
        echo "Test Report - $(date)"
        echo "=================="
        echo
        for category in "${!test_categories[@]}"; do
            echo "Category: $category"
            echo "Result: $(run_tests $category && echo 'PASS' || echo 'FAIL')"
            echo
        done
    } > "$TEST_REPORT"
}

main() {
    local failed=0
    
    echo "Starting automated tests at $(date)"
    
    for category in "${!test_categories[@]}"; do
        if ! run_tests "$category"; then
            failed=1
        fi
    done
    
    generate_report
    
    if [ $failed -eq 1 ]; then
        echo "Some tests failed. Check $TEST_REPORT for details."
        exit 1
    else
        echo "All tests passed! Report available at $TEST_REPORT"
        exit 0
    fi
}

main 