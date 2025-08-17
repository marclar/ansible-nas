#!/bin/bash

# Script to set up passwordless sudo for Ansible operations
# This needs to be run on the target server

echo "Setting up passwordless sudo for Ansible operations..."

# Create sudoers file for mk user with all necessary permissions
sudo tee /etc/sudoers.d/ansible-nas <<EOF
# Ansible-NAS passwordless sudo configuration
# User mk can run all commands without password for automation
mk ALL=(ALL) NOPASSWD: ALL
EOF

# Validate the sudoers file
sudo visudo -c -f /etc/sudoers.d/ansible-nas

if [ $? -eq 0 ]; then
    echo "✅ Sudo configuration successfully applied"
    echo "You can now run Ansible playbooks without sudo password prompts"
else
    echo "❌ Error in sudoers configuration"
    sudo rm /etc/sudoers.d/ansible-nas
    exit 1
fi