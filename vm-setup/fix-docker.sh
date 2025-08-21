#!/bin/bash

# Fix Docker issues on Ubuntu VM

echo "Diagnosing and fixing Docker issues..."
echo "======================================="
echo ""

# Check Docker status
echo "1. Checking Docker service status..."
sudo systemctl status docker --no-pager | head -10

# Check for common issues
echo ""
echo "2. Checking for conflicting packages..."
dpkg -l | grep -E "docker|containerd" | grep -v "^rc"

# Check if docker.io and docker-ce are both installed
if dpkg -l | grep -q "docker.io" && dpkg -l | grep -q "docker-ce"; then
    echo ""
    echo "⚠️  Found both docker.io and docker-ce installed - this causes conflicts!"
    echo "Fixing by removing docker.io..."
    sudo apt-get remove -y docker.io
    sudo apt-get autoremove -y
fi

# Check storage driver issues
echo ""
echo "3. Checking Docker daemon configuration..."
if [ -f /etc/docker/daemon.json ]; then
    echo "Current daemon.json:"
    cat /etc/docker/daemon.json
else
    echo "No daemon.json found (using defaults)"
fi

# Fix common permission issues
echo ""
echo "4. Fixing permissions..."
sudo chmod 666 /var/run/docker.sock 2>/dev/null || true
sudo usermod -aG docker $USER

# Check for disk space issues
echo ""
echo "5. Checking disk space..."
df -h / /var/lib/docker 2>/dev/null

# Try to restart Docker
echo ""
echo "6. Attempting to restart Docker..."
sudo systemctl stop docker
sudo systemctl stop docker.socket
sudo systemctl stop containerd

# Clean up any stale files
sudo rm -f /var/run/docker.pid 2>/dev/null

# Start services in order
sudo systemctl start docker.socket
sudo systemctl start containerd
sudo systemctl start docker

# Check final status
echo ""
echo "7. Final status check..."
if sudo systemctl is-active --quiet docker; then
    echo "✅ Docker is running!"
    docker version
    echo ""
    echo "Testing Docker..."
    docker run --rm hello-world
else
    echo "❌ Docker failed to start. Checking logs..."
    sudo journalctl -xeu docker.service --no-pager | tail -30
    echo ""
    echo "Additional debugging:"
    sudo dockerd --debug 2>&1 | head -20
fi

echo ""
echo "======================================="
echo "Diagnostics complete!"
echo ""
echo "If Docker is still not working, try:"
echo "1. Reboot the VM: sudo reboot"
echo "2. Reinstall Docker: sudo apt-get purge docker* && sudo apt-get install docker.io"