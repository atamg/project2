# High-Availability Kubernetes Platform

## Overview
This project implements a production-grade, highly available Kubernetes platform with supporting services. The platform includes a 3-node controller plane, 3-node worker configuration, and various supporting services implemented using Infrastructure as Code principles. It automates the deployment of a highly available Kubernetes cluster and associated applications using Terraform, Ansible, and Helm.

## System Architecture
- Multi-node Kubernetes cluster with no Single Point of Failure (SPOF).
- Out-of-cluster dependencies like container registry and CI/CD tools.
- Centralized monitoring, logging, and backup systems.

## Prerequisites
- AWS Account with appropriate permissions
- Linux/Unix environment (e.g., Ubuntu 20.04)
- Internet connectivity
- Tools: Terraform, Ansible, Helm, kubectl, Docker, Git

## Quick Start
```bash
# Clone the repository
git clone https://github.com/atamg/project2.git
cd project2

# Set your AWS credentials
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"

# Run the installation
./install.sh
```

## Deployment Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/atamg/project2.git
   cd project2
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

3. Validate the cluster:
   ```bash
   ./scripts/validate-cluster.sh
   ```

## Deployment Environments

This project supports deployment to both AWS and local VirtualBox environments. By default, deployment is local (VirtualBox). To change the environment, set the `DEPLOYMENT_ENV` variable before running `install.sh`:

- For local VirtualBox (default):
  ```bash
  export DEPLOYMENT_ENV=virtualbox
  ./install.sh
  ```
- For AWS:
  ```bash
  export DEPLOYMENT_ENV=aws
  ./install.sh
  ```

The Terraform code and Ansible playbooks will use the selected environment for provisioning and configuration.

## Components
- **Infrastructure**: Deployed using Terraform.
- **Kubernetes Cluster**: Configured using Ansible.
- **Applications**: Deployed using Helm.
- **Monitoring & Logging**: Centralized systems with alerting.
- **Backup & Restore**: Automated backups with monitoring.

## Security Features
- RBAC enabled
- Network policies
- Pod security policies
- Regular security scanning (using Trivy and Lynis)
- TLS everywhere
- Jump server access control
- Hardened servers with CIS Benchmarks
- Restricted external ports (22, 80, 443)

## Authentication
- Centralized authentication using Keycloak.

## Documentation
- [Infrastructure Setup](docs/infrastructure.md)
- [Security Configuration](docs/security.md)
- [Monitoring Setup](docs/monitoring.md)
- [Backup Procedures](docs/backup.md)
- [Troubleshooting Guide](docs/troubleshooting.md)

## Application Deployment with ArgoCD

This project uses [ArgoCD](https://argo-cd.readthedocs.io/) for GitOps-based deployment of all Kubernetes applications. All application manifests are stored in the `kubernetes/argocd-apps/` directory. To deploy all apps:

1. Install ArgoCD in your cluster (see the official docs).
2. Apply the ArgoCD Application manifests:
   ```bash
   kubectl apply -n argocd -f kubernetes/argocd-apps/
   ```
3. ArgoCD will sync and manage all applications automatically from this repository.

## ArgoCD Bootstrap

To automate the deployment of all platform applications, use the ArgoCD bootstrap Application manifest:

1. Install ArgoCD in your cluster (see the official docs).
2. Apply the bootstrap manifest:
   ```bash
   kubectl apply -n argocd -f kubernetes/argocd-apps/argocd-bootstrap.yaml
   ```
3. The bootstrap Application will automatically create and manage all other ArgoCD Applications from this repository.