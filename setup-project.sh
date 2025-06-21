#!/bin/bash

# Create project structure
mkdir -p kubernetes-ha-platform/{ansible/{inventory,playbooks,roles},terraform/{modules/{vpc,ec2,rds},environments/{prod,staging}},kubernetes/charts,docker-compose,scripts,reports}

# Create base files
touch kubernetes-ha-platform/README.md
touch kubernetes-ha-platform/install.sh
chmod +x kubernetes-ha-platform/install.sh 