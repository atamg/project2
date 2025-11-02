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

package_update: true
packages:
  - rsync

# Optional: ensure the root filesystem expands automatically
growpart:
  mode: auto
  devices: ['/']
  ignore_growroot_disabled: false

bootcmd:
  # Wait for attached disks (vdb and vdc expected)
  - 'sleep 5'

runcmd:
  # Identify attached disks (adjust if device order changes)
  - VAR_DEV="/dev/vdb"
  - HOME_DEV="/dev/vdc"

  # Create filesystems (if not already formatted)
  - 'blkid "$VAR_DEV" || mkfs.xfs -L var "$VAR_DEV"'
  - 'blkid "$HOME_DEV" || mkfs.xfs -L home "$HOME_DEV"'

  # Create temp mountpoints
  - 'mkdir -p /mnt/var-new /mnt/home-new'

  # Mount new disks
  - 'mount /dev/disk/by-label/var  /mnt/var-new'
  - 'mount /dev/disk/by-label/home /mnt/home-new'

  # Copy current data safely
  - 'rsync -aXS --exclude="/var/tmp/*" /var/  /mnt/var-new/'
  - 'rsync -aXS /home/ /mnt/home-new/'

  # Replace original dirs
  - 'mv /var /var.old && mkdir /var'
  - 'mv /home /home.old && mkdir /home'

  # Persist in fstab using UUIDs
  - 'echo "UUID=$(blkid -s UUID -o value /dev/disk/by-label/var)  /var  xfs   defaults        0 2"  >> /etc/fstab'
  - 'echo "UUID=$(blkid -s UUID -o value /dev/disk/by-label/home) /home xfs   defaults,nodev 0 2"  >> /etc/fstab'
  - 'echo "tmpfs  /tmp  tmpfs  nodev,nosuid,noexec,size=2G  0 0"  >> /etc/fstab'

  # Mount everything
  - 'mount -a'

  # Ensure permissions
  - 'chmod 1777 /tmp'
  - 'chown root:root /var'

  # Log setup
  - 'echo "Custom mounts for /var, /home, /tmp applied successfully." > /root/disk-setup.log'
  # Configure networking
  - |
    cat > /etc/netplan/60-static.yaml << 'EOF'
    network:
      version: 2
      ethernets:
        ens3:
          dhcp4: false
          addresses: [${ip}/24]
          routes:
            - to: 0.0.0.0/0
              via: ${gateway}
          nameservers:
            addresses: [8.8.8.8, 1.1.1.1]
    EOF
  - 'chmod 600 /etc/netplan/60-static.yaml'
  - 'netplan apply'