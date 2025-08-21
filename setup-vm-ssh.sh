#!/bin/bash

# Setup SSH key authentication for VM

VM_IP="192.168.64.2"
VM_USER="mk"

echo "Setting up SSH key authentication for Ubuntu VM"
echo "================================================"
echo ""
echo "VM IP: $VM_IP"
echo "VM User: $VM_USER"
echo ""

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa.pub ]; then
    echo "No SSH key found. Creating one..."
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
fi

echo "Copying SSH key to VM..."
echo "You'll be prompted for your VM password:"
ssh-copy-id ${VM_USER}@${VM_IP}

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SSH key successfully copied!"
    echo ""
    echo "Testing passwordless connection..."
    ssh ${VM_USER}@${VM_IP} "echo '✅ SSH key authentication working!'"
else
    echo ""
    echo "❌ Failed to copy SSH key. Please check your password and try again."
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Test Ansible connection: ansible -i inventories/vm/inventory nas -m ping"
echo "2. Run VM setup script on the VM: ssh ${VM_USER}@${VM_IP} 'bash -s' < vm-setup/ubuntu-setup.sh"