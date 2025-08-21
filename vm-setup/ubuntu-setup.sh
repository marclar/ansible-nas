#!/bin/bash

# Ubuntu VM Initial Setup Script for Ansible-NAS
# Run this after installing Ubuntu Server in your VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_status "Ubuntu VM Setup for Ansible-NAS"
echo ""

# Get network information
print_status "Network Configuration"
IP_ADDRESS=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -1)
print_success "VM IP Address: $IP_ADDRESS"

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_success "System updated"

# Install essential packages
print_status "Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    htop \
    vim \
    net-tools \
    nfs-common \
    docker.io \
    docker-compose \
    python3-pip \
    python3-venv \
    build-essential \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ffmpeg

print_success "Essential packages installed"

# Configure Docker
print_status "Configuring Docker..."
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker
print_success "Docker configured (logout and login for group changes to take effect)"

# Install Ansible
print_status "Installing Ansible..."
sudo apt-add-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
print_success "Ansible installed"

# Create directory structure
print_status "Creating directory structure..."
sudo mkdir -p /mnt/truenas-media
sudo mkdir -p /home/$USER/docker
sudo chown -R $USER:$USER /home/$USER/docker
print_success "Directories created"

# Configure NFS mount for TrueNAS
print_status "Configuring NFS mount..."
echo ""
print_warning "Enter your TrueNAS NFS share details:"
read -p "TrueNAS IP address [192.168.12.227]: " TRUENAS_IP
TRUENAS_IP=${TRUENAS_IP:-192.168.12.227}

read -p "NFS share path [/mnt/pool0/media]: " NFS_PATH
NFS_PATH=${NFS_PATH:-/mnt/pool0/media}

# Test NFS mount
print_status "Testing NFS mount..."
sudo mount -t nfs ${TRUENAS_IP}:${NFS_PATH} /mnt/truenas-media

if mountpoint -q /mnt/truenas-media; then
    print_success "NFS mount successful!"
    
    # Add to fstab for permanent mounting
    print_status "Adding NFS mount to /etc/fstab..."
    echo "# TrueNAS NFS mount" | sudo tee -a /etc/fstab
    echo "${TRUENAS_IP}:${NFS_PATH} /mnt/truenas-media nfs defaults,_netdev,auto 0 0" | sudo tee -a /etc/fstab
    print_success "NFS mount configured for auto-mount on boot"
else
    print_error "NFS mount failed. Please check your TrueNAS settings."
    print_warning "You can manually configure this later"
fi

# Configure system limits for containers
print_status "Configuring system limits..."
echo "fs.file-max = 2097152" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
echo "net.core.rmem_max=2500000" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
print_success "System limits configured"

# Configure swappiness for better container performance
print_status "Optimizing swap settings..."
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
print_success "Swap optimized for containers"

# Install Python requirements for Ansible-NAS
print_status "Installing Python requirements..."
# Use system packages for Ubuntu 22.04+ (PEP 668 compliance)
sudo apt install -y python3-pip python3-docker python3-docker-compose
# Alternative: use pipx for user installations
sudo apt install -y pipx
pipx ensurepath
# Or use virtual environment for additional packages if needed
python3 -m venv ~/ansible-venv 2>/dev/null || true
print_success "Python requirements installed"

# Clone Ansible-NAS repository
print_status "Cloning Ansible-NAS repository..."
if [ ! -d "$HOME/ansible-nas" ]; then
    git clone https://github.com/davestephens/ansible-nas.git $HOME/ansible-nas
    print_success "Ansible-NAS cloned to $HOME/ansible-nas"
else
    print_warning "Ansible-NAS already exists at $HOME/ansible-nas"
fi

# Create VM-specific inventory
print_status "Creating VM-specific inventory..."
mkdir -p $HOME/ansible-nas/inventories/vm
cat > $HOME/ansible-nas/inventories/vm/inventory << EOF
[nas]
localhost ansible_connection=local

[all:vars]
ansible_python_interpreter=/usr/bin/python3
EOF
print_success "VM inventory created"

# Set up CPU governor for better performance
print_status "Configuring CPU governor..."
sudo apt install -y cpufrequtils
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
sudo systemctl restart cpufrequtils 2>/dev/null || true
print_success "CPU governor set to performance mode"

# Configure firewall
print_status "Configuring firewall..."
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 32400/tcp  # Plex
sudo ufw allow 9090/tcp   # Cockpit (optional)
print_warning "Firewall rules added but NOT enabled. Enable with: sudo ufw enable"

# Install Cockpit for web-based management (optional)
print_status "Installing Cockpit (web-based management)..."
sudo apt install -y cockpit cockpit-docker
sudo systemctl enable --now cockpit.socket
print_success "Cockpit installed - access at https://${IP_ADDRESS}:9090"

# Display summary
echo ""
echo "========================================="
echo -e "${GREEN}Ubuntu VM Setup Complete!${NC}"
echo "========================================="
echo ""
echo "VM IP Address: $IP_ADDRESS"
echo "NFS Mount: ${TRUENAS_IP}:${NFS_PATH} → /mnt/truenas-media"
echo "Ansible-NAS: $HOME/ansible-nas"
echo "Docker: Installed and configured"
echo "Cockpit: https://${IP_ADDRESS}:9090"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Logout and login for Docker group changes"
echo "2. Configure Ansible-NAS inventory: ~/ansible-nas/inventories/vm/group_vars/nas.yml"
echo "3. Run Ansible-NAS playbook: cd ~/ansible-nas && ansible-playbook -i inventories/vm/inventory nas.yml"
echo ""
echo -e "${YELLOW}Optional:${NC}"
echo "- Enable firewall: sudo ufw enable"
echo "- Configure static IP in /etc/netplan/ if needed"
echo "- Set up SSH keys for passwordless access"
echo ""
print_success "Setup script completed successfully!"