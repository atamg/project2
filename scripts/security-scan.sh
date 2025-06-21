#!/bin/bash

log_info() {
    echo -e "\033[0;32m[INFO]\033[0m $1"
}

log_info "Scanning images with Trivy..."
trivy image my-app:latest
