#!/bin/bash

# Post-deployment configuration script for Ansible-NAS
# This script ensures API keys are synchronized between services and Homepage

set -e

echo "=== Post-Deployment Configuration ==="
echo "Synchronizing API keys between services and Homepage"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="${1:-192.168.12.100}"
VAULT_PASS_FILE="${2:-.vault_pass}"

echo "Server IP: $SERVER_IP"
echo ""

# Function to update vault with a key
update_vault_key() {
    local key_name=$1
    local key_value=$2
    
    echo -n "Updating $key_name in vault... "
    
    # Decrypt vault
    ansible-vault decrypt inventories/production/group_vars/nas/vault.yml \
        --vault-password-file="$VAULT_PASS_FILE" \
        --output=/tmp/vault_temp.yml 2>/dev/null
    
    # Update the key
    sed -i '' "s/${key_name}: .*/${key_name}: \"${key_value}\"/" /tmp/vault_temp.yml
    
    # Re-encrypt vault
    ansible-vault encrypt /tmp/vault_temp.yml \
        --vault-password-file="$VAULT_PASS_FILE" \
        --output=inventories/production/group_vars/nas/vault.yml 2>/dev/null
    
    rm /tmp/vault_temp.yml
    echo -e "${GREEN}✓${NC}"
}

# Wait for services to be ready
echo "Waiting for services to initialize..."
sleep 10

# Get Radarr API Key
echo -n "Getting Radarr API key... "
RADARR_KEY=$(ssh mk@$SERVER_IP "docker exec radarr cat /config/config.xml 2>/dev/null | grep -oP '(?<=<ApiKey>)[^<]+'" 2>/dev/null || echo "")
if [ -n "$RADARR_KEY" ]; then
    echo -e "${GREEN}$RADARR_KEY${NC}"
    update_vault_key "vault_radarr_api_key" "$RADARR_KEY"
else
    echo -e "${YELLOW}Not found (service may not be running)${NC}"
fi

# Get Sonarr API Key
echo -n "Getting Sonarr API key... "
SONARR_KEY=$(ssh mk@$SERVER_IP "docker exec sonarr cat /config/config.xml 2>/dev/null | grep -oP '(?<=<ApiKey>)[^<]+'" 2>/dev/null || echo "")
if [ -n "$SONARR_KEY" ]; then
    echo -e "${GREEN}$SONARR_KEY${NC}"
    update_vault_key "vault_sonarr_api_key" "$SONARR_KEY"
else
    echo -e "${YELLOW}Not found (service may not be running)${NC}"
fi

# Get SABnzbd API Key
echo -n "Getting SABnzbd API key... "
SABNZBD_KEY=$(ssh mk@$SERVER_IP "docker exec sabnzbd cat /config/sabnzbd.ini 2>/dev/null | grep '^api_key' | cut -d' ' -f3" 2>/dev/null || echo "")
if [ -n "$SABNZBD_KEY" ]; then
    echo -e "${GREEN}$SABNZBD_KEY${NC}"
    update_vault_key "vault_sabnzbd_api_key" "$SABNZBD_KEY"
else
    echo -e "${YELLOW}Not found (service may not be running)${NC}"
fi

# Get Plex Token (if needed)
echo -n "Checking Plex token... "
PLEX_KEY=$(ansible-vault view inventories/production/group_vars/nas/vault.yml --vault-password-file="$VAULT_PASS_FILE" 2>/dev/null | grep vault_plex_api_key | cut -d'"' -f2)
if [ -n "$PLEX_KEY" ]; then
    echo -e "${GREEN}Already configured${NC}"
else
    echo -e "${YELLOW}Manual configuration needed${NC}"
    echo "  Visit https://plex.1815.space and get token from:"
    echo "  Settings > Network > Show Advanced > API Token"
fi

echo ""
echo "Redeploying Homepage with updated API keys..."
ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_PASS_FILE" ansible-playbook \
    -i inventories/production/inventory nas.yml \
    --tags "homepage" \
    -e ansible_python_interpreter=/usr/bin/python3

echo ""
echo -e "${GREEN}✓ Post-deployment configuration complete${NC}"
echo ""
echo "All API keys have been synchronized. Homepage widgets should work correctly."
echo "Visit https://home.1815.space to verify."