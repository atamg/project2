variable "masters" {
  type    = number
  default = 3
}

variable "workers" {
  type    = number
  default = 3
}

variable "memory" {
  type    = number
  default = 4096
}

variable "cpu" {
  type    = number
  default = 4
}

variable "password" {
  description = "Encrypted password (openssl passwd -6)"
  default     = "$6$gJoKWBs2aHUWxB.Q$pBO0apwmdCuHjZaALQOIQyH10SVXoHJoIJFIBj4usXRI03ABizQ.anHncXDQqfuIiosITYwiqTRnhhoV9iAj30"
}

variable "ssh_key_path" {
  default = "/home/ata/.ssh/ata_rsa.pub"
}

variable "jump_server_ip" {
  default = "192.168.122.100"
}

variable "master_ips" {
  default = ["192.168.122.101", "192.168.122.102", "192.168.122.103"]
}

variable "worker_ips" {
  default = ["192.168.122.104", "192.168.122.105", "192.168.122.106"]
}

variable "lb_ips" {
  description = "IP addresses for load-balancer nodes lb-1, lb-2"
  default     = ["192.168.122.51", "192.168.122.52"]
}

############################
# Locals
############################

locals {
  gateway_ip = "192.168.122.1"

  master_var_disk_size_bytes  = var.master_var_disk_size_gb * 1024 * 1024 * 1024
  master_home_disk_size_bytes = var.master_home_disk_size_gb * 1024 * 1024 * 1024

  worker_var_disk_size_bytes  = var.worker_var_disk_size_gb * 1024 * 1024 * 1024
  worker_home_disk_size_bytes = var.worker_home_disk_size_gb * 1024 * 1024 * 1024

  jump_var_disk_size_bytes  = var.jump_var_disk_size_gb * 1024 * 1024 * 1024
  jump_home_disk_size_bytes = var.jump_home_disk_size_gb * 1024 * 1024 * 1024

  lb_var_disk_size_bytes  = var.lb_var_disk_size_gb * 1024 * 1024 * 1024
  lb_home_disk_size_bytes = var.lb_home_disk_size_gb * 1024 * 1024 * 1024
}


# Per-role data disk sizes (GB)
variable "master_var_disk_size_gb" {
  type    = number
  default = 20
}
variable "master_home_disk_size_gb" {
  type    = number
  default = 5
}

variable "worker_var_disk_size_gb" {
  type    = number
  default = 20
}
variable "worker_home_disk_size_gb" {
  type    = number
  default = 5
}

variable "jump_var_disk_size_gb" {
  type    = number
  default = 20
}
variable "jump_home_disk_size_gb" {
  type    = number
  default = 20
}

# LB node disk sizes
variable "lb_var_disk_size_gb" {
  type    = number
  default = 20
}
variable "lb_home_disk_size_gb" {
  type    = number
  default = 5
}
