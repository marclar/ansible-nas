#!/bin/bash

# Deployment script for Standalone PC
# This script helps deploy Ansible-NAS to your standalone Ubuntu PC

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INVENTORY="inventories/standalone/inventory"
PLAYBOOK="nas.yml"
VAULT_PASS_FILE=".vault_pass"

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}  Ansible-NAS Standalone Deployment${NC}"
echo -e "${GREEN}==================================${NC}"
echo

# Check if running from the correct directory
if [ ! -f "$PLAYBOOK" ]; then
    echo -e "${RED}Error: Please run this script from the ansible-nas root directory${NC}"
    exit 1
fi

# Check if inventory exists
if [ ! -f "$INVENTORY" ]; then
    echo -e "${RED}Error: Standalone inventory not found at $INVENTORY${NC}"
    echo -e "${YELLOW}Have you configured your standalone inventory yet?${NC}"
    exit 1
fi

# Check current network configuration
echo -e "${YELLOW}Current Network Configuration:${NC}"
grep "ansible_nas_server_ip:" inventories/standalone/group_vars/nas/network.yml || true
grep "local_network_subnet:" inventories/standalone/group_vars/nas/network.yml || true
grep "truenas_server_ip:" inventories/standalone/group_vars/nas/network.yml || true
echo

# Confirm configuration
read -p "Is this configuration correct for your standalone PC? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Please update inventories/standalone/group_vars/nas/network.yml with your network settings${NC}"
    exit 1
fi

# Check vault password file
if [ ! -f "$VAULT_PASS_FILE" ]; then
    echo -e "${YELLOW}Vault password file not found. Please create .vault_pass with your vault password${NC}"
    exit 1
fi

# Menu for deployment options
echo -e "${GREEN}Select deployment option:${NC}"
echo "1) Full deployment (all enabled services)"
echo "2) Network check only (verify connectivity)"
echo "3) Deploy specific service(s)"
echo "4) Dry run (check what would be deployed)"
echo "5) Update Homepage only"
echo "6) Deploy core services (Traefik, Homepage, Portainer)"
echo "7) Deploy media stack (Plex, Radarr, Sonarr, etc.)"
echo "8) Exit"
echo

read -p "Enter your choice [1-8]: " choice

case $choice in
    1)
        echo -e "${GREEN}Starting full deployment...${NC}"
        ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --vault-password-file "$VAULT_PASS_FILE"
        ;;
    2)
        echo -e "${GREEN}Running network connectivity check...${NC}"
        ansible -i "$INVENTORY" all -m ping
        echo
        echo -e "${GREEN}Testing NFS mount availability...${NC}"
        ansible -i "$INVENTORY" all -m shell -a "showmount -e \$(grep truenas_server_ip inventories/standalone/group_vars/nas/network.yml | cut -d'\"' -f2) || echo 'NFS server not reachable'"
        ;;
    3)
        read -p "Enter service name(s) to deploy (comma-separated, e.g., plex,radarr): " services
        echo -e "${GREEN}Deploying: $services${NC}"
        ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --tags "$services" --vault-password-file "$VAULT_PASS_FILE"
        ;;
    4)
        echo -e "${GREEN}Running dry run...${NC}"
        ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --check --vault-password-file "$VAULT_PASS_FILE"
        ;;
    5)
        echo -e "${GREEN}Updating Homepage...${NC}"
        ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --tags "homepage" --vault-password-file "$VAULT_PASS_FILE"
        ;;
    6)
        echo -e "${GREEN}Deploying core services...${NC}"
        ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --tags "traefik,homepage,portainer" --vault-password-file "$VAULT_PASS_FILE"
        ;;
    7)
        echo -e "${GREEN}Deploying media stack...${NC}"
        ansible-playbook -i "$INVENTORY" "$PLAYBOOK" --tags "plex,radarr,sonarr,bazarr,prowlarr,sabnzbd,transmission" --vault-password-file "$VAULT_PASS_FILE"
        ;;
    8)
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac

echo
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}==================================${NC}"
echo
echo -e "${YELLOW}Service URLs (update IPs as needed):${NC}"
echo "Homepage: http://\$(grep ansible_nas_server_ip inventories/standalone/group_vars/nas/network.yml | cut -d'\"' -f2):11111"
echo "Traefik:  http://\$(grep ansible_nas_server_ip inventories/standalone/group_vars/nas/network.yml | cut -d'\"' -f2):8083"
echo
echo -e "${YELLOW}For external access, ensure Cloudflare Tunnel is configured${NC}"