variable "vm_image" {
  default = "../../image/image.tar.xz"
}

variable "base_ip" {
  default = "192.168.56"
}

variable "masters" {
  default = ["master1", "master2", "master3"]
}

variable "workers" {
  default = ["worker1", "worker2", "worker3"]
}

variable "memory" {
  default = "2048 mib"
}

variable "cpus" {
  default = 2
}
