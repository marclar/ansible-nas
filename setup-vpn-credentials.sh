#!/bin/bash

echo "======================================"
echo "Setup VPN Credentials for Privado"
echo "======================================"
echo ""
echo "Your credentials will be stored securely in the vault file"
echo ""

# Read VPN credentials
read -p "Enter your Privado VPN username: " VPN_USER
echo ""
read -s -p "Enter your Privado VPN password: " VPN_PASS
echo ""
echo ""

# Optional server selection
echo "Server location (optional):"
echo "1. USA (default)"
echo "2. Canada"
echo "3. Netherlands"
echo "4. Switzerland"
echo "5. Custom"
read -p "Select [1-5, or press Enter for USA]: " SERVER_CHOICE

case $SERVER_CHOICE in
    2)
        SERVER="Canada"
        ;;
    3)
        SERVER="Netherlands"
        ;;
    4)
        SERVER="Switzerland"
        ;;
    5)
        read -p "Enter country name: " SERVER
        ;;
    *)
        SERVER="USA"
        ;;
esac

echo ""
echo "Updating vault file..."

# Append to vault file
cat >> inventories/vm/group_vars/nas/vault.yml << EOF

# VPN Credentials for Privado
vault_vpn_username: "$VPN_USER"
vault_vpn_password: "$VPN_PASS"
vault_vpn_server: "$SERVER"
EOF

echo "✅ VPN credentials saved to vault"

# Update the main configuration with server
if [ "$SERVER" != "USA" ]; then
    sed -i.bak "s/gluetun_server_countries: \"USA\"/gluetun_server_countries: \"$SERVER\"/" inventories/vm/group_vars/nas/main.yml
fi

echo ""
echo "======================================"
echo "Ready to deploy VPN configuration"
echo "======================================"
echo ""
echo "The deployment will:"
echo "1. Create Gluetun VPN container"
echo "2. Reconfigure Transmission to use VPN"
echo "3. Reconfigure SABnzbd to use VPN"
echo "4. All download traffic will go through Privado VPN"
echo ""
echo "Run: ansible-playbook -i inventories/vm/inventory nas.yml --tags 'gluetun,transmission,sabnzbd'"