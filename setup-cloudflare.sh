#!/bin/bash

# Setup Cloudflare for Ansible-NAS VM

echo "======================================"
echo "Cloudflare Setup for Ansible-NAS"
echo "======================================"
echo ""
echo "This script will help you configure Cloudflare for SSL certificates"
echo "and optional tunnel access to your services."
echo ""

# Check if vault already exists
if [ -f "inventories/vm/group_vars/nas/vault.yml" ]; then
    echo "⚠️  Vault file already exists at inventories/vm/group_vars/nas/vault.yml"
    read -p "Do you want to recreate it? (y/n): " recreate
    if [ "$recreate" != "y" ]; then
        echo "Keeping existing vault file."
        exit 0
    fi
fi

echo "Step 1: Cloudflare API Token (Required for SSL)"
echo "------------------------------------------------"
echo "1. Go to: https://dash.cloudflare.com/profile/api-tokens"
echo "2. Click 'Create Token'"
echo "3. Use template 'Edit zone DNS' or create custom token with:"
echo "   - Permissions: Zone > DNS > Edit"
echo "   - Zone Resources: Include > Specific zone > 1815.space"
echo "4. Create token and copy it"
echo ""
read -p "Enter your Cloudflare API Token: " CF_API_TOKEN

echo ""
echo "Step 2: Cloudflare Tunnel (Optional)"
echo "-------------------------------------"
echo "This allows access to services via subdomains without opening ports."
echo ""
read -p "Do you want to set up a Cloudflare Tunnel? (y/n): " setup_tunnel

if [ "$setup_tunnel" = "y" ]; then
    echo ""
    echo "Setting up Cloudflare Tunnel:"
    echo "1. Go to: https://one.dash.cloudflare.com/"
    echo "2. Navigate to Networks > Tunnels"
    echo "3. Click 'Create a tunnel'"
    echo "4. Name it: ansible-nas-vm"
    echo "5. Copy the tunnel token"
    echo ""
    read -p "Enter your Cloudflare Tunnel Token: " CF_TUNNEL_TOKEN
    TUNNEL_ENABLED="true"
else
    CF_TUNNEL_TOKEN=""
    TUNNEL_ENABLED="false"
fi

echo ""
echo "Step 3: Plex Claim Token (Optional)"
echo "------------------------------------"
echo "This links Plex to your Plex account automatically."
echo ""
read -p "Do you want to set up Plex claim token? (y/n): " setup_plex

if [ "$setup_plex" = "y" ]; then
    echo ""
    echo "1. Go to: https://www.plex.tv/claim"
    echo "2. Copy the claim token (valid for 4 minutes)"
    echo ""
    read -p "Enter your Plex Claim Token: " PLEX_CLAIM
else
    PLEX_CLAIM=""
fi

# Create vault file
echo ""
echo "Creating vault file..."
cat > inventories/vm/group_vars/nas/vault.yml << EOF
---
# Cloudflare API Token for Traefik SSL certificates
vault_traefik_cf_dns_api_token: "$CF_API_TOKEN"

# Cloudflare Tunnel Token
vault_cloudflare_tunnel_token: "$CF_TUNNEL_TOKEN"

# Plex Claim Token
vault_plex_claim_token: "$PLEX_CLAIM"
EOF

echo "✅ Vault file created at inventories/vm/group_vars/nas/vault.yml"

# Update main.yml to enable tunnel if configured
if [ "$TUNNEL_ENABLED" = "true" ]; then
    echo ""
    echo "Enabling Cloudflare Tunnel in configuration..."
    sed -i.bak 's/cloudflare_tunnel_enabled: false/cloudflare_tunnel_enabled: true/' inventories/vm/group_vars/nas/main.yml
    echo "✅ Cloudflare Tunnel enabled"
fi

echo ""
echo "======================================"
echo "Setup Complete!"
echo "======================================"
echo ""
echo "✅ Cloudflare API Token configured for SSL certificates"
if [ "$TUNNEL_ENABLED" = "true" ]; then
    echo "✅ Cloudflare Tunnel configured for secure access"
    echo ""
    echo "Next steps for tunnel:"
    echo "1. Configure tunnel routes in Cloudflare dashboard:"
    echo "   - home.1815.space → http://localhost:11111"
    echo "   - plex.1815.space → http://localhost:32400"
    echo "   - radarr.1815.space → http://localhost:7878"
    echo "   - sonarr.1815.space → http://localhost:8989"
    echo "   etc."
fi
echo ""
echo "You can now run the deployment:"
echo "./deploy-vm.sh"
echo ""
echo "Services will be available at:"
if [ "$TUNNEL_ENABLED" = "true" ]; then
    echo "  https://home.1815.space (via tunnel)"
    echo "  https://plex.1815.space (via tunnel)"
else
    echo "  https://home.1815.space (with SSL)"
    echo "  http://home.1815.space:11111 (direct)"
fi