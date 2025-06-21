#!/bin/bash

# Disaster Recovery Script
set -e

BACKUP_BUCKET="mecan-k8s-backups"
RESTORE_POINT=""
LOG_FILE="/var/log/disaster-recovery.log"

# Logging setup
exec 1> >(tee -a "$LOG_FILE") 2>&1

print_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  --restore-point YYYY-MM-DD-HHMMSS  Specify backup timestamp to restore"
    echo "  --dry-run                          Perform a dry run"
    echo "  --help                             Show this help message"
}

check_prerequisites() {
    echo "Checking prerequisites..."
    for cmd in kubectl velero aws; do
        if ! command -v $cmd &> /dev/null; then
            echo "Error: $cmd is required but not installed."
            exit 1
        fi
    done
}

validate_cluster_access() {
    echo "Validating cluster access..."
    if ! kubectl cluster-info &> /dev/null; then
        echo "Error: Cannot access Kubernetes cluster"
        exit 1
    fi
}

list_available_backups() {
    echo "Available backups:"
    velero backup get
}

restore_cluster() {
    local restore_point=$1
    local dry_run=$2
    
    echo "Starting cluster restore process..."
    
    # Validate backup exists
    if ! velero backup get $restore_point &> /dev/null; then
        echo "Error: Backup $restore_point not found"
        exit 1
    }
    
    if [ "$dry_run" = true ]; then
        echo "Performing dry run restore..."
        velero restore create --from-backup $restore_point --dry-run
        return
    fi
    
    echo "Performing full restore..."
    velero restore create --from-backup $restore_point --wait
    
    # Verify restore
    echo "Verifying restore..."
    kubectl get nodes
    kubectl get pods --all-namespaces
}

main() {
    local dry_run=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --restore-point)
                RESTORE_POINT="$2"
                shift 2
                ;;
            --dry-run)
                dry_run=true
                shift
                ;;
            --help)
                print_usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    check_prerequisites
    validate_cluster_access
    
    if [ -z "$RESTORE_POINT" ]; then
        list_available_backups
        exit 0
    fi
    
    restore_cluster "$RESTORE_POINT" "$dry_run"
}

main "$@" 