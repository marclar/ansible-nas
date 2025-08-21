#!/bin/bash

# Setup passwordless sudo and SSH for Ansible deployments

VM_HOST="home.1815.space"
VM_USER="mk"

echo "======================================"
echo "Setting up passwordless access for Ansible"
echo "======================================"
echo ""

# Step 1: Setup SSH key authentication
echo "Step 1: Setting up SSH key authentication..."
if ! ssh -o PasswordAuthentication=no -o ConnectTimeout=2 ${VM_USER}@${VM_HOST} "echo 'SSH key works'" 2>/dev/null; then
    echo "Setting up SSH key..."
    ssh-copy-id ${VM_USER}@${VM_HOST}
    echo "✅ SSH key configured"
else
    echo "✅ SSH key already configured"
fi

# Step 2: Configure passwordless sudo on VM
echo ""
echo "Step 2: Configuring passwordless sudo on VM..."
echo "You'll need to enter your password one more time for this setup:"
echo ""

# Create sudoers file for the user
ssh -t ${VM_USER}@${VM_HOST} "echo '${VM_USER} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${VM_USER}"

# Verify it worked
if ssh ${VM_USER}@${VM_HOST} "sudo -n echo 'Passwordless sudo works'" 2>/dev/null; then
    echo "✅ Passwordless sudo configured successfully"
else
    echo "❌ Failed to configure passwordless sudo"
    exit 1
fi

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "✅ SSH key authentication is configured"
echo "✅ Passwordless sudo is enabled for user '${VM_USER}'"
echo ""
echo "You can now run Ansible playbooks without password prompts:"
echo "  ansible-playbook -i inventories/vm/inventory nas.yml"
echo ""
echo "Security Note: The VM user now has full sudo access without password."
echo "This is convenient for automation but reduces security."