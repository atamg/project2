#cloud-config
hostname: ${hostname}
users:
  - name: ata
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    passwd: "${password}"
    ssh_authorized_keys:
      - ${ssh_key}
ssh_pwauth: true
