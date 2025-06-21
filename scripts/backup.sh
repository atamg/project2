#!/bin/bash

# Backup script for Kubernetes cluster components
# Configuration
BACKUP_DIR="/backup"
S3_BUCKET="mecan-k8s-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=30

# Logging setup
LOGFILE="/var/log/k8s-backup.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

# Check required tools
check_requirements() {
    command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required but not installed."; exit 1; }
    command -v aws >/dev/null 2>&1 || { echo "aws cli is required but not installed."; exit 1; }
}

# Create backup directory
create_backup_dir() {
    mkdir -p "${BACKUP_DIR}/${TIMESTAMP}"
}

# Backup etcd
backup_etcd() {
    echo "Backing up etcd..."
    ETCDCTL_API=3 etcdctl snapshot save \
        "${BACKUP_DIR}/${TIMESTAMP}/etcd-snapshot.db"
}

# Backup Kubernetes resources
backup_k8s_resources() {
    echo "Backing up Kubernetes resources..."
    
    # Backup all namespaces
    kubectl get namespaces -o json > "${BACKUP_DIR}/${TIMESTAMP}/namespaces.json"
    
    # Backup resources for each namespace
    for ns in $(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}'); do
        mkdir -p "${BACKUP_DIR}/${TIMESTAMP}/${ns}"
        
        for resource in deployments statefulsets configmaps secrets services ingresses pvc; do
            kubectl get -n ${ns} ${resource} -o json > "${BACKUP_DIR}/${TIMESTAMP}/${ns}/${resource}.json"
        done
    done
}

# Backup persistent volumes
backup_persistent_volumes() {
    echo "Backing up persistent volumes..."
    kubectl get pv -o json > "${BACKUP_DIR}/${TIMESTAMP}/persistent-volumes.json"
}

# Upload to S3
upload_to_s3() {
    echo "Uploading backup to S3..."
    aws s3 cp "${BACKUP_DIR}/${TIMESTAMP}" "s3://${S3_BUCKET}/${TIMESTAMP}" \
        --recursive \
        --storage-class STANDARD_IA
}

# Cleanup old backups
cleanup_old_backups() {
    echo "Cleaning up old backups..."
    
    # Local cleanup
    find ${BACKUP_DIR} -type d -mtime +${RETENTION_DAYS} -exec rm -rf {} \;
    
    # S3 cleanup
    aws s3 ls "s3://${S3_BUCKET}" | while read -r line; do
        createDate=$(echo $line | awk '{print $1" "$2}')
        createDate=$(date -d "$createDate" +%s)
        olderThan=$(date -d "-${RETENTION_DAYS} days" +%s)
        
        if [[ $createDate -lt $olderThan ]]; then
            fileName=$(echo $line | awk '{print $4}')
            if [[ $fileName != "" ]]; then
                aws s3 rm "s3://${S3_BUCKET}/${fileName}"
            fi
        fi
    done
}

# Main execution
main() {
    echo "Starting backup at $(date)"
    
    check_requirements
    create_backup_dir
    backup_etcd
    backup_k8s_resources
    backup_persistent_volumes
    upload_to_s3
    cleanup_old_backups
    
    echo "Backup completed at $(date)"
}

main 