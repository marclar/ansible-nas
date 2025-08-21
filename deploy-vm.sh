#!/bin/bash

# Ansible-NAS VM Deployment Script

echo "======================================"
echo "Ansible-NAS VM Deployment"
echo "======================================"
echo ""
echo "Target: home.1815.space"
echo ""

# Check if we can SSH without password
if ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no mk@home.1815.space "echo 'SSH key auth OK'" 2>/dev/null; then
    echo "✅ SSH key authentication configured"
    SSH_ARGS=""
else
    echo "⚠️  SSH key not configured, will prompt for password"
    SSH_ARGS="-k"
fi

# Function to deploy specific services
deploy_services() {
    local tags=$1
    local description=$2
    
    echo ""
    echo "Deploying: $description"
    echo "Tags: $tags"
    echo "----------------------------------------"
    
    ansible-playbook -i inventories/vm/inventory nas.yml \
        --tags "$tags" \
        $SSH_ARGS \
        -K
    
    if [ $? -eq 0 ]; then
        echo "✅ $description deployed successfully"
    else
        echo "❌ Failed to deploy $description"
        return 1
    fi
}

# Menu
echo ""
echo "Select deployment option:"
echo "1. Core services (Docker, Traefik, Homepage)"
echo "2. Media services (Plex, Radarr, Sonarr, etc.)"
echo "3. Download services (Transmission, SABnzbd)"
echo "4. Management tools (Portainer, Watchtower)"
echo "5. Everything enabled in config"
echo "6. Custom tags (you specify)"
echo ""
read -p "Enter choice [1-6]: " choice

case $choice in
    1)
        # Deploy Docker first, then other core services
        echo "Note: Deploying in stages to handle dependencies..."
        deploy_services "docker" "Docker"
        if [ $? -eq 0 ]; then
            deploy_services "traefik,homepage" "Traefik and Homepage"
        fi
        ;;
    2)
        deploy_services "plex,radarr,sonarr,bazarr,prowlarr,overseerr" "Media services"
        ;;
    3)
        deploy_services "transmission,sabnzbd" "Download services"
        ;;
    4)
        deploy_services "portainer,watchtower,netdata" "Management tools"
        ;;
    5)
        echo "Deploying all enabled services..."
        ansible-playbook -i inventories/vm/inventory nas.yml $SSH_ARGS -K
        ;;
    6)
        read -p "Enter tags (comma-separated): " custom_tags
        deploy_services "$custom_tags" "Custom services"
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "======================================"
echo "Deployment complete!"
echo ""
echo "Check services:"
echo "- Homepage: http://home.1815.space:11111"
echo "- Traefik: http://home.1815.space:8083"
echo "- Portainer: http://home.1815.space:9000"
echo ""
echo "Run 'docker ps' on VM to see running containers"
echo "======================================"