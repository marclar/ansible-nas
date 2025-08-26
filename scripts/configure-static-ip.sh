#!/bin/bash

# Configure Static IP for Ansible-NAS VM
# This script sets up a static IP to prevent DHCP reassignment

set -e

# Configuration
DESIRED_IP="192.168.12.100"
GATEWAY="192.168.12.1"  # Adjust if your gateway is different
NETMASK="255.255.255.0"
DNS1="8.8.8.8"
DNS2="8.8.4.4"
INTERFACE="eth0"  # May need to adjust - could be ens33, ens160, etc.

echo "=== Static IP Configuration for Ansible-NAS VM ==="
echo ""
echo "This script will configure a static IP address for your VM"
echo "Target IP: $DESIRED_IP"
echo ""

# Detect Ubuntu version and network management system
if command -v netplan >/dev/null 2>&1; then
    echo "Detected Netplan (Ubuntu 18.04+)"
    echo ""
    
    # Create netplan configuration
    cat > /tmp/01-netcfg.yaml << EOF
# Static IP configuration for Ansible-NAS
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $DESIRED_IP/24
      gateway4: $GATEWAY
      nameservers:
        addresses:
          - $DNS1
          - $DNS2
EOF
    
    echo "Configuration to be applied:"
    cat /tmp/01-netcfg.yaml
    echo ""
    
    # Apply configuration
    echo "Backing up existing netplan configuration..."
    sudo cp /etc/netplan/*.yaml /tmp/netplan-backup-$(date +%Y%m%d-%H%M%S).yaml 2>/dev/null || true
    
    echo "Applying new configuration..."
    sudo cp /tmp/01-netcfg.yaml /etc/netplan/01-netcfg.yaml
    
    echo "Testing configuration..."
    sudo netplan try --timeout 120
    
    if [ $? -eq 0 ]; then
        echo "Configuration successful! Applying permanently..."
        sudo netplan apply
    else
        echo "Configuration test failed. Reverting..."
        exit 1
    fi
    
elif [ -f /etc/network/interfaces ]; then
    echo "Detected traditional networking (/etc/network/interfaces)"
    echo ""
    
    # Backup existing configuration
    sudo cp /etc/network/interfaces /etc/network/interfaces.backup-$(date +%Y%m%d-%H%M%S)
    
    # Create new configuration
    cat > /tmp/interfaces << EOF
# Static IP configuration for Ansible-NAS
auto lo
iface lo inet loopback

auto $INTERFACE
iface $INTERFACE inet static
    address $DESIRED_IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS1 $DNS2
EOF
    
    echo "Configuration to be applied:"
    cat /tmp/interfaces
    echo ""
    
    # Apply configuration
    sudo cp /tmp/interfaces /etc/network/interfaces
    
    echo "Restarting networking..."
    sudo systemctl restart networking || sudo service networking restart
    
else
    echo "ERROR: Unable to detect network configuration system"
    echo "You may need to configure static IP manually"
    exit 1
fi

echo ""
echo "=== Static IP Configuration Complete ==="
echo ""
echo "VM should now have static IP: $DESIRED_IP"
echo ""
echo "To verify:"
echo "  ip addr show"
echo "  ping $GATEWAY"
echo ""
echo "If you lose connectivity, reboot the VM to apply changes"