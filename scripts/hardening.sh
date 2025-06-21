#!/bin/bash

# System hardening script following CIS benchmarks
# Log file setup
LOGFILE="/var/log/system-hardening.log"
exec 1> >(tee -a "$LOGFILE") 2>&1

echo "Starting system hardening at $(date)"

# Function to backup files before modification
backup_file() {
    if [ -f "$1" ]; then
        cp "$1" "$1.bak.$(date +%Y%m%d)"
    fi
}

# 1. File System Configuration
configure_filesystem() {
    echo "Configuring filesystem security..."
    
    # Set critical file permissions
    chmod 644 /etc/passwd
    chmod 000 /etc/shadow
    chmod 644 /etc/group
    
    # Configure sticky bit on world-writable directories
    df --local -P | awk '{if (NR!=1) print $6}' | xargs -I '{}' find '{}' -xdev -type d -perm -0002 2>/dev/null | xargs chmod a+t
}

# 2. Configure SSH
secure_ssh() {
    echo "Securing SSH configuration..."
    backup_file "/etc/ssh/sshd_config"
    
    # SSH hardening configurations
    cat > /etc/ssh/sshd_config << EOF
Protocol 2
LogLevel VERBOSE
PermitRootLogin no
MaxAuthTries 3
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
KerberosAuthentication no
GSSAPIAuthentication no
X11Forwarding no
AllowAgentForwarding no
AllowTcpForwarding no
PermitUserEnvironment no
ClientAliveInterval 300
ClientAliveCountMax 0
EOF

    systemctl restart sshd
}

# 3. Configure System Authentication
configure_auth() {
    echo "Configuring system authentication..."
    
    # Password policies
    backup_file "/etc/login.defs"
    sed -i 's/PASS_MAX_DAYS.*/PASS_MAX_DAYS 90/' /etc/login.defs
    sed -i 's/PASS_MIN_DAYS.*/PASS_MIN_DAYS 7/' /etc/login.defs
    sed -i 's/PASS_WARN_AGE.*/PASS_WARN_AGE 7/' /etc/login.defs
    
    # Configure PAM
    backup_file "/etc/pam.d/common-password"
    echo "password requisite pam_pwquality.so retry=3 minlen=14 dcredit=-1 ucredit=-1 ocredit=-1 lcredit=-1" >> /etc/pam.d/common-password
}

# 4. Network Security
configure_network() {
    echo "Configuring network security..."
    
    # Configure kernel parameters
    cat > /etc/sysctl.d/99-security.conf << EOF
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.tcp_syncookies = 1
EOF

    sysctl -p /etc/sysctl.d/99-security.conf
}

# 5. Audit Configuration
configure_audit() {
    echo "Configuring system auditing..."
    
    # Install auditd if not present
    if ! command -v auditd &> /dev/null; then
        apt-get update && apt-get install -y auditd
    fi
    
    # Configure audit rules
    cat > /etc/audit/rules.d/audit.rules << EOF
-w /etc/passwd -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudo_actions
-w /var/log/auth.log -p wa -k auth_logs
EOF

    service auditd restart
}

# Main execution
main() {
    configure_filesystem
    secure_ssh
    configure_auth
    configure_network
    configure_audit
    
    echo "System hardening completed at $(date)"
}

main 