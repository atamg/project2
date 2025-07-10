terraform {
  required_providers {
    virtualbox = {
      source  = "terra-farm/virtualbox"
      version = "0.2.2-alpha.1"
    }
  }
}

provider "virtualbox" {}

resource "virtualbox_vm" "masters" {
  count  = length(var.masters)
  name   = var.masters[count.index]
  image  = var.vm_image
  cpus   = var.cpus
  memory = var.memory

  network_adapter {
    device         = "IntelPro1000MTDesktop"
    type           = "bridged"
    host_interface = "wlp9s0"
  }
}

resource "virtualbox_vm" "workers" {
  count  = length(var.workers)
  name   = var.workers[count.index]
  image  = var.vm_image
  cpus   = var.cpus
  memory = var.memory

  network_adapter {
    device         = "IntelPro1000MTDesktop"
    type           = "bridged"
    host_interface = "wlp9s0"
  }
}
