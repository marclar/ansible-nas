#!/bin/bash

echo "=== Ansible-NAS Deployment Script ==="
echo "Deploying local changes to production environment"
echo ""

# Set script to exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Check if we're in the right directory
if [ ! -f "nas.yml" ] || [ ! -d "inventories" ]; then
    print_status $RED "Error: This doesn't appear to be an Ansible-NAS directory"
    print_status $YELLOW "Please run this script from the root of your Ansible-NAS project"
    exit 1
fi

# Check if production inventory exists
if [ ! -f "inventories/production/inventory" ]; then
    print_status $RED "Error: Production inventory file not found"
    print_status $YELLOW "Expected: inventories/production/inventory"
    exit 1
fi

# Check for vault password file
VAULT_FILE=".vault_pass"
if [ ! -f "$VAULT_FILE" ]; then
    print_status $YELLOW "⚠️  Vault password file not found: $VAULT_FILE"
    print_status $YELLOW "   Creating one now. Please change the default password!"
    echo "changeme-use-a-strong-password-here" > $VAULT_FILE
    chmod 600 $VAULT_FILE
    print_status $GREEN "✅ Created $VAULT_FILE with default password"
    print_status $RED "   IMPORTANT: Edit $VAULT_FILE and set a strong password!"
    echo ""
    read -p "Press Enter to continue after setting your password..."
fi

print_status $BLUE "📋 Pre-deployment checks..."

# Check if target host is reachable
TARGET_HOST=$(grep -E "^[0-9]" inventories/production/inventory | head -1 | awk '{print $1}' || echo "")
if [ -z "$TARGET_HOST" ]; then
    print_status $RED "Error: Cannot determine target host from inventory"
    exit 1
fi

print_status $BLUE "🎯 Target host: $TARGET_HOST"

# Test connectivity
print_status $BLUE "🔍 Testing connectivity to $TARGET_HOST..."
if ! ping -c 1 -W 3 $TARGET_HOST > /dev/null 2>&1; then
    print_status $RED "Error: Cannot reach target host $TARGET_HOST"
    print_status $YELLOW "Please check your network connection and host availability"
    exit 1
fi

print_status $GREEN "✅ Host is reachable"

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    print_status $RED "Error: ansible-playbook command not found"
    print_status $YELLOW "Please install Ansible or ensure it's in your PATH"
    print_status $YELLOW "Install with: pip install -r requirements-dev.txt"
    exit 1
fi

print_status $GREEN "✅ Ansible found: $(ansible-playbook --version | head -1)"

# Check for local changes (git status if this is a git repo)
if [ -d ".git" ]; then
    print_status $BLUE "📝 Checking for local changes..."
    if ! git diff --quiet || ! git diff --cached --quiet; then
        print_status $YELLOW "⚠️  You have uncommitted local changes"
        git status --porcelain
        echo ""
        read -p "Continue with deployment? (y/N): " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status $YELLOW "Deployment cancelled"
            exit 1
        fi
    else
        print_status $GREEN "✅ No uncommitted changes"
    fi
fi

# Check if passwordless sudo is configured
SSH_TEST=$(ssh -o BatchMode=yes -o ConnectTimeout=5 mk@$TARGET_HOST "sudo -n ls /root 2>&1" 2>/dev/null || echo "FAIL")
if [[ "$SSH_TEST" == "FAIL" ]] || [[ "$SSH_TEST" == *"password"* ]]; then
    print_status $YELLOW "⚠️  Passwordless sudo not configured"
    print_status $YELLOW "   You will be prompted for sudo password during deployment"
    SUDO_FLAG="-K"
else
    print_status $GREEN "✅ Passwordless sudo configured"
    SUDO_FLAG=""
fi

# Show deployment options
echo ""
print_status $BLUE "🚀 Deployment Options:"
echo "  1) Full deployment (all services)"
echo "  2) Specific services only"
echo "  3) Dry run (check what would be deployed)"
echo "  4) Update configurations only"
echo "  5) Sync API keys (run after fresh deployment)"
echo ""

read -p "Choose deployment option (1-5): " -n 1 -r DEPLOY_OPTION
echo ""

case $DEPLOY_OPTION in
    1)
        print_status $GREEN "🚀 Starting full deployment..."
        ANSIBLE_CMD="ansible-playbook -i inventories/production/inventory nas.yml --vault-password-file $VAULT_FILE $SUDO_FLAG"
        ;;
    2)
        echo ""
        print_status $BLUE "Available service tags:"
        print_status $YELLOW "  Media: plex, radarr, sonarr, bazarr, prowlarr, overseerr"
        print_status $YELLOW "  Downloads: transmission, sabnzbd, gluetun"
        print_status $YELLOW "  System: traefik, homepage, cloudflare_tunnel"
        echo ""
        read -p "Enter service tags (comma-separated): " TAGS
        if [ -z "$TAGS" ]; then
            print_status $RED "No tags specified, exiting"
            exit 1
        fi
        ANSIBLE_CMD="ansible-playbook -i inventories/production/inventory nas.yml --tags $TAGS --vault-password-file $VAULT_FILE $SUDO_FLAG"
        ;;
    3)
        print_status $GREEN "🔍 Running deployment dry-run..."
        ANSIBLE_CMD="ansible-playbook -i inventories/production/inventory nas.yml --check --vault-password-file $VAULT_FILE $SUDO_FLAG"
        ;;
    4)
        print_status $GREEN "📝 Updating configurations only..."
        ANSIBLE_CMD="ansible-playbook -i inventories/production/inventory nas.yml --tags config --vault-password-file $VAULT_FILE $SUDO_FLAG"
        ;;
    5)
        print_status $GREEN "🔄 Syncing API keys from running services..."
        echo ""
        if [ -f "./post_deploy_config.sh" ]; then
            ./post_deploy_config.sh "$TARGET_HOST" "$VAULT_FILE"
            exit $?
        else
            print_status $RED "Error: post_deploy_config.sh not found"
            exit 1
        fi
        ;;
    *)
        print_status $RED "Invalid option selected"
        exit 1
        ;;
esac

# Show what will be executed
echo ""
print_status $BLUE "🔧 Executing: $ANSIBLE_CMD"
echo ""

# Ask for confirmation
if [[ $DEPLOY_OPTION != "3" ]]; then
    read -p "Proceed with deployment? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status $YELLOW "Deployment cancelled"
        exit 1
    fi
fi

# Record start time
START_TIME=$(date +%s)

print_status $GREEN "🚀 Starting deployment at $(date)"
echo ""

# Execute Ansible playbook
if $ANSIBLE_CMD; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    print_status $GREEN "✅ Deployment completed successfully!"
    print_status $GREEN "⏱️  Duration: ${DURATION} seconds"
    
    if [[ $DEPLOY_OPTION != "3" ]]; then
        echo ""
        print_status $BLUE "🔗 Service URLs:"
        print_status $YELLOW "  Homepage: https://home.1815.space"
        print_status $YELLOW "  Plex: https://plex.1815.space"
        print_status $YELLOW "  Radarr: https://radarr.1815.space"
        print_status $YELLOW "  Sonarr: https://sonarr.1815.space"
        print_status $YELLOW "  Traefik Dashboard: http://$TARGET_HOST:8083"
        echo ""
        print_status $BLUE "🔐 Remember: All services require Basic Auth"
        print_status $BLUE "   Username: admin"
        print_status $BLUE "   Password: isn't that a fine how-do-u-do!"
    fi
else
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo ""
    print_status $RED "❌ Deployment failed after ${DURATION} seconds"
    print_status $YELLOW "Check the error messages above for details"
    exit 1
fi

echo ""
print_status $GREEN "🎉 Deployment complete!"