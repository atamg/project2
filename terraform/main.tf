provider "aws" {
  region = var.aws_region
  count  = var.deployment_env == "aws" ? 1 : 0
}

provider "virtualbox" {
  count = var.deployment_env == "virtualbox" ? 1 : 0
}

# VPC/Network modules
module "vpc" {
  source = var.deployment_env == "aws" ? "./modules/vpc" : "./modules/vbox_network"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  project_name       = var.project_name
}

# Security groups or firewall rules
module "security_groups" {
  source = var.deployment_env == "aws" ? "./modules/security" : "./modules/vbox_security"
  vpc_id = module.vpc.vpc_id
}

# Kubernetes masters
module "k8s_masters" {
  source = var.deployment_env == "aws" ? "./modules/ec2" : "./modules/vbox_vm"
  count  = 3
  name               = "master-${count.index + 1}"
  instance_type      = var.master_instance_type
  subnet_id          = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
  security_group_ids = [module.security_groups.k8s_masters_sg_id]
  key_name           = var.ssh_key_name
  tags = {
    Name        = "k8s-master-${count.index + 1}"
    Environment = var.environment
    Role        = "master"
  }
}

# Kubernetes workers
module "k8s_workers" {
  source = var.deployment_env == "aws" ? "./modules/ec2" : "./modules/vbox_vm"
  count  = 3
  name               = "worker-${count.index + 1}"
  instance_type      = var.worker_instance_type
  subnet_id          = module.vpc.private_subnets[count.index % length(module.vpc.private_subnets)]
  security_group_ids = [module.security_groups.k8s_workers_sg_id]
  key_name           = var.ssh_key_name
  tags = {
    Name        = "k8s-worker-${count.index + 1}"
    Environment = var.environment
    Role        = "worker"
  }
}

# Jump server
module "jump_server" {
  source = var.deployment_env == "aws" ? "./modules/ec2" : "./modules/vbox_vm"
  name               = "jump-server"
  instance_type      = var.jump_server_instance_type
  subnet_id          = module.vpc.public_subnets[0]
  security_group_ids = [module.security_groups.jump_server_sg_id]
  key_name           = var.ssh_key_name
  tags = {
    Name        = "jump-server"
    Environment = var.environment
    Role        = "jump"
  }
}