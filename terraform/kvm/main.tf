terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.6.14"
    }
    template = {
      source  = "hashicorp/template"
      version = ">= 2.2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.1"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}



############################
# Base image
############################
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu24.04.qcow2"
  pool   = "default"
  source = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
  format = "qcow2"

  provisioner "local-exec" {
    command = "sudo chown libvirt-qemu:kvm ${self.id}"
  }
}

############################
# Root disks
############################
resource "libvirt_volume" "master_disk" {
  count          = var.masters
  name           = "master-${count.index}.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = 10737418240
}

resource "libvirt_volume" "worker_disk" {
  count          = var.workers
  name           = "worker-${count.index}.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = 10737418240
}

resource "libvirt_volume" "jump_server_disk" {
  name           = "jump_server.qcow2"
  base_volume_id = libvirt_volume.ubuntu_base.id
  pool           = "default"
  size           = 10737418240
}

############################
# Data disks for /var and /home
############################
# Masters
resource "libvirt_volume" "master_var_disk" {
  count  = var.masters
  name   = "master-${count.index}-var.qcow2"
  pool   = "default"
  size   = local.master_var_disk_size_bytes
  format = "qcow2"
}

resource "libvirt_volume" "master_home_disk" {
  count  = var.masters
  name   = "master-${count.index}-home.qcow2"
  pool   = "default"
  size   = local.master_home_disk_size_bytes
  format = "qcow2"
}

# Workers
resource "libvirt_volume" "worker_var_disk" {
  count  = var.workers
  name   = "worker-${count.index}-var.qcow2"
  pool   = "default"
  size   = local.worker_var_disk_size_bytes
  format = "qcow2"
}

resource "libvirt_volume" "worker_home_disk" {
  count  = var.workers
  name   = "worker-${count.index}-home.qcow2"
  pool   = "default"
  size   = local.worker_home_disk_size_bytes
  format = "qcow2"
}

# Jump server
resource "libvirt_volume" "jump_server_var_disk" {
  name   = "jump-server-var.qcow2"
  pool   = "default"
  size   = local.jump_var_disk_size_bytes
  format = "qcow2"
}

resource "libvirt_volume" "jump_server_home_disk" {
  name   = "jump-server-home.qcow2"
  pool   = "default"
  size   = local.jump_home_disk_size_bytes
  format = "qcow2"
}

############################
# Data sources (ssh key + cloud-init templates + net cfg)
############################
data "local_file" "ssh_key" {
  filename = abspath(var.ssh_key_path)
}

# Masters cloud-init & network
data "template_file" "cloud_init_master" {
  count    = var.masters
  template = file("${path.module}/cloud_init_master.tpl")
  vars = {
    hostname = "k8s-master-${count.index + 1}"
    password = var.password
    ssh_key  = data.local_file.ssh_key.content
    ip       = var.master_ips[count.index]
    gateway  = local.gateway_ip
  }
}

data "template_file" "network_config_master" {
  count    = length(var.master_ips)
  template = file("${path.module}/network_config.cfg")
  vars = {
    ip      = var.master_ips[count.index]
    gateway = local.gateway_ip
  }
}

resource "libvirt_cloudinit_disk" "cloudinit_master" {
  count          = var.masters
  name           = "cloudinit-master-${count.index}.iso"
  user_data      = data.template_file.cloud_init_master[count.index].rendered
  network_config = data.template_file.network_config_master[count.index].rendered
  pool           = "default"
}

# Workers cloud-init & network
data "template_file" "cloud_init_worker" {
  count    = var.workers
  template = file("${path.module}/cloud_init_worker.tpl")
  vars = {
    hostname = "k8s-worker-${count.index + 1}"
    password = var.password
    ssh_key  = data.local_file.ssh_key.content
    ip       = var.worker_ips[count.index]
    gateway  = local.gateway_ip
  }
}

data "template_file" "network_config_worker" {
  count    = length(var.worker_ips)
  template = file("${path.module}/network_config.cfg")
  vars = {
    ip      = var.worker_ips[count.index]
    gateway = local.gateway_ip
  }
}

resource "libvirt_cloudinit_disk" "cloudinit_worker" {
  count          = var.workers
  name           = "cloudinit-worker-${count.index}.iso"
  user_data      = data.template_file.cloud_init_worker[count.index].rendered
  network_config = data.template_file.network_config_worker[count.index].rendered
  pool           = "default"
}

# Jump server cloud-init & network
data "template_file" "cloud_init_jump_server" {
  template = file("${path.module}/cloud_init_jump_server.tpl")
  vars = {
    hostname = "jump-server"
    password = var.password
    ssh_key  = data.local_file.ssh_key.content
    ip       = var.jump_server_ip
    gateway  = local.gateway_ip
  }
}

data "template_file" "network_config_jump_server" {
  template = file("${path.module}/network_config.cfg")
  vars = {
    ip      = var.jump_server_ip
    gateway = local.gateway_ip
  }
}

resource "libvirt_cloudinit_disk" "cloudinit_jump_server" {
  name           = "cloudinit-jump-server.iso"
  user_data      = data.template_file.cloud_init_jump_server.rendered
  network_config = data.template_file.network_config_jump_server.rendered
  pool           = "default"
}

############################
# Domains
############################
resource "libvirt_domain" "masters" {
  count  = var.masters
  name   = "k8s-master-${count.index + 1}"
  memory = var.memory
  vcpu   = var.cpu

  # root disk
  disk { volume_id = libvirt_volume.master_disk[count.index].id }

  # data disks
  disk { volume_id = libvirt_volume.master_var_disk[count.index].id }
  disk { volume_id = libvirt_volume.master_home_disk[count.index].id }

  cloudinit = libvirt_cloudinit_disk.cloudinit_master[count.index].id

  network_interface { network_name = "default" }

  graphics {
    type        = "spice"
    listen_type = "none"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

resource "libvirt_domain" "workers" {
  count  = var.workers
  name   = "k8s-worker-${count.index + 1}"
  memory = var.memory
  vcpu   = var.cpu

  # root disk
  disk { volume_id = libvirt_volume.worker_disk[count.index].id }

  # data disks
  disk { volume_id = libvirt_volume.worker_var_disk[count.index].id }
  disk { volume_id = libvirt_volume.worker_home_disk[count.index].id }

  cloudinit = libvirt_cloudinit_disk.cloudinit_worker[count.index].id

  network_interface { network_name = "default" }

  graphics {
    type        = "spice"
    listen_type = "none"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

resource "libvirt_domain" "jump_server" {
  name   = "jump-server"
  memory = var.memory
  vcpu   = var.cpu

  # root disk
  disk { volume_id = libvirt_volume.jump_server_disk.id }

  # data disks
  disk { volume_id = libvirt_volume.jump_server_var_disk.id }
  disk { volume_id = libvirt_volume.jump_server_home_disk.id }

  cloudinit = libvirt_cloudinit_disk.cloudinit_jump_server.id

  network_interface { network_name = "default" }

  graphics {
    type        = "spice"
    listen_type = "none"
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

############################
# Outputs
############################
output "master_nodes_map" {
  value = { for idx, ip in var.master_ips : "master-${idx + 1}" => ip }
}

output "worker_nodes_map" {
  value = { for idx, ip in var.worker_ips : "worker-${idx + 1}" => ip }
}

output "jump_server_map" {
  value = { "jump-server" = var.jump_server_ip }
}
