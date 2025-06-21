#!/bin/bash

# Disaster Recovery Script
set -e

BACKUP_LOCATION="s3://mecan-k8s-backups"
RESTORE_POINT=""
COMPONENTS=(
    "etcd"
    "kubernetes-resources"
    "persistent-volumes"
    "certificates"
)

backup_etcd() {
    echo "Backing up etcd..."
    ETCDCTL_API=3 etcdctl snapshot save \
        --endpoints=https://127.0.0.1:2379 \
        --cacert=/etc/kubernetes/pki/etcd/ca.crt \
        --cert=/etc/kubernetes/pki/etcd/server.crt \
        --key=/etc/kubernetes/pki/etcd/server.key \
        etcd-snapshot.db
}

backup_kubernetes_resources() {
    echo "Backing up Kubernetes resources..."
    
    # Backup all namespaces
    for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
        kubectl -n $ns get all -o yaml > k8s-backup-$ns.yaml
    done
    
    # Backup CRDs and their resources
    kubectl get crd -o yaml > crds.yaml
}

restore_etcd() {
    echo "Restoring etcd..."
    ETCDCTL_API=3 etcdctl snapshot restore etcd-snapshot.db \
        --data-dir /var/lib/etcd-restore
    
    # Update etcd data directory
    sed -i 's/\/var\/lib\/etcd/\/var\/lib\/etcd-restore/g' \
        /etc/kubernetes/manifests/etcd.yaml
}

restore_kubernetes_resources() {
    echo "Restoring Kubernetes resources..."
    
    # Restore CRDs first
    kubectl apply -f crds.yaml
    
    # Restore namespace resources
    for backup in k8s-backup-*.yaml; do
        kubectl apply -f $backup
    done
}

perform_backup() {
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_dir="backup-$timestamp"
    
    mkdir -p $backup_dir
    
    for component in "${COMPONENTS[@]}"; do
        backup_${component} $backup_dir
    done
    
    # Upload to S3
    aws s3 cp $backup_dir $BACKUP_LOCATION/$backup_dir --recursive
}

perform_restore() {
    if [ -z "$RESTORE_POINT" ]; then
        echo "No restore point specified"
        exit 1
    fi
    
    # Download from S3
    aws s3 cp $BACKUP_LOCATION/$RESTORE_POINT . --recursive
    
    for component in "${COMPONENTS[@]}"; do
        restore_${component}
    done
}

main() {
    case $1 in
        backup)
            perform_backup
            ;;
        restore)
            RESTORE_POINT=$2
            perform_restore
            ;;
        *)
            echo "Usage: $0 {backup|restore [restore-point]}"
            exit 1
            ;;
    esac
}

main "$@" 