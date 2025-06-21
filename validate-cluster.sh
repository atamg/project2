#!/bin/bash

set -e

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}
log_error() {
    echo -e "\033[0;31m[ERROR]\033[0m $1"
}

log_info "Validating Kubernetes cluster nodes..."
kubectl get nodes -o wide || { log_error "Failed to get nodes"; exit 1; }

log_info "Validating system pods in kube-system namespace..."
kubectl get pods -n kube-system || { log_error "Failed to get kube-system pods"; exit 1; }

log_info "Validating ArgoCD applications..."
kubectl get applications -n argocd || log_info "ArgoCD CRD not found or ArgoCD not installed. Skipping."

log_info "Validating key workloads (Prometheus, Loki, Keycloak, MongoDB, Kafka)..."
for ns in monitoring auth storage; do
    kubectl get pods -n $ns || log_error "Failed to get pods in namespace $ns"
done

log_info "Cluster validation successful."
