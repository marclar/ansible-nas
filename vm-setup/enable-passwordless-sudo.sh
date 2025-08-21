#!/bin/bash

# Run this script ON THE VM to enable passwordless sudo

echo "Enabling passwordless sudo for user $USER..."
echo "$USER ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$USER

# Set correct permissions
sudo chmod 0440 /etc/sudoers.d/$USER

# Test it
if sudo -n echo "✅ Passwordless sudo is now enabled!"; then
    echo ""
    echo "You can now run Ansible deployments without password prompts."
    echo "Security note: Your user has full sudo access without password."
else
    echo "❌ Something went wrong. Check /etc/sudoers.d/$USER"
fi