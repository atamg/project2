#!/bin/bash

# Configuration
DEPLOYMENT_ENV=${DEPLOYMENT_ENV:-kvm}
export DEPLOYMENT_ENV
INSTALL_DEPENDENCY=${INSTALL_DEPENDENCY:-false}
LOG_DIR="./reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Required tools
REQUIRED_TOOLS=(
    "terraform"
    "ansible"
    "kubectl"
    "helm"
    "aws"
    "docker"
    "git"
    "genisoimage"
)

# Log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        log_error "Unsupported operating system."
        exit 1
    fi
}

# Install dependency based on OS
install_dependency() {
    local tool=$1

    case "$OS" in
        ubuntu|debian)
            sudo apt-get update && sudo apt-get install -y "$tool"
            ;;
        centos|rhel|fedora)
            sudo yum install -y "$tool"
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

# Check and install required tools
check_and_install_tools() {
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_warn "$tool is not installed. Installing..."
            install_dependency "$tool"
        else
            log_info "$tool is already installed."
        fi
    done
}

# Create log directory
create_log_dir() {
    if [[ ! -d "$LOG_DIR" ]]; then
        mkdir -p "$LOG_DIR"
        log_info "Log directory created at $LOG_DIR"
    fi
}

# Deploy infrastructure using Terraform
deploy_infrastructure() {
    log_info "Deploying infrastructure using Terraform for environment: $DEPLOYMENT_ENV ..."
    if [[ $DEPLOYMENT_ENV == "vbox" ]]; then
        log_warn "Using VirtualBox environment. Ensure VirtualBox is installed and configured."
        cd ./terraform/vbox
        terraform fmt
        terraform validate
        terraform init
        TF_LOG=DEBUG TF_LOG_PATH=terraform-debug.log terraform apply -auto-approve
        if [[ $? -ne 0 ]]; then
            log_error "Terraform deployment failed."
            exit 1
        fi
        terraform output -json all_nodes > nodes.json
        log_info "Infrastructure deployed successfully."
    elif [[ "$DEPLOYMENT_ENV" == "aws" ]]; then
        log_warn "Using AWS environment. Ensure AWS CLI is configured."
        cd ./terraform/aws
        terraform fmt
        terraform validate
        terraform init
        terraform apply -auto-approve
        if [[ $? -ne 0 ]]; then
            log_error "Terraform deployment failed."
            exit 1
        fi
        terraform output -json all_nodes > nodes.json
        log_info "Infrastructure deployed successfully."
    elif [[ "$DEPLOYMENT_ENV" == "kvm" ]]; then
        log_warn "Using KVM environment. Ensure libvirt is installed and configured."
        cd ./terraform/kvm
        terraform fmt
        terraform validate
        terraform init
        terraform apply -parallelism=1 -auto-approve
        if [[ $? -ne 0 ]]; then
            log_error "Terraform deployment failed."
            exit 1
        fi
        terraform output -json all_nodes > nodes.json
        log_info "Infrastructure deployed successfully."
    fi

    
}

# Configure Kubernetes cluster using Ansible
configure_kubernetes() {
    log_info "Configuring Kubernetes cluster using Ansible for environment: $DEPLOYMENT_ENV ..."
    ansible-playbook -e deployment_env=$DEPLOYMENT_ENV -i ansible/inventory/hosts.yml ansible/playbooks/k8s-cluster.yml
    if [[ $? -ne 0 ]]; then
        log_error "Kubernetes configuration failed."
        exit 1
    fi
    log_info "Kubernetes cluster configured successfully."
}

# Deploy applications using Helm
deploy_applications() {
    log_info "Deploying applications using Helm..."
    helm repo update
    helm upgrade --install my-app ./kubernetes/charts/my-app
    if [[ $? -ne 0 ]]; then
        log_error "Application deployment failed."
        exit 1
    fi
    log_info "Applications deployed successfully."
}

# Main script execution
main() {
    detect_os
    create_log_dir

    if [[ "$INSTALL_DEPENDENCY" == "true" ]]; then
        check_and_install_tools
    else
        log_info "Dependency installation is disabled. Skipping..."
    fi

    deploy_infrastructure
    #configure_kubernetes
    #deploy_applications
}

main "$@"