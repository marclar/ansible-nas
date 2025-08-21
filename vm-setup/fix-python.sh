#!/bin/bash

# Fix Python requirements for Ubuntu 22.04+

echo "Fixing Python requirements for Ubuntu 22.04+"
echo "============================================="

# Install system Python packages
echo "Installing system Python packages..."
sudo apt update
sudo apt install -y \
    python3-pip \
    python3-docker \
    python3-yaml \
    python3-jinja2 \
    python3-paramiko \
    python3-cryptography

# Install pipx for isolated user installations
echo "Installing pipx..."
sudo apt install -y pipx
pipx ensurepath

# Install ansible via pipx (optional, since we already have it from apt)
# pipx install ansible-core

echo ""
echo "✅ Python environment fixed!"
echo ""
echo "The externally-managed-environment error is resolved."
echo "Ansible and Docker Python modules are now available system-wide."
echo ""
echo "You can now continue with Ansible-NAS deployment."