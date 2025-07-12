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

locals {
  gateway_ip = "192.168.122.1"
}

