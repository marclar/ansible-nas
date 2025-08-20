#!/bin/bash

# Migration Script: Physical NAS to Ubuntu VM
# This script helps migrate Docker volumes and configurations from your physical NAS to the VM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Configuration
PHYSICAL_NAS_IP="192.168.12.210"
PHYSICAL_NAS_USER="mk"
VM_IP=""
VM_USER="mk"

# Get VM details
print_status "Migration from Physical NAS to VM"
echo ""
read -p "Enter VM IP address: " VM_IP
read -p "Enter VM username [mk]: " VM_USER
VM_USER=${VM_USER:-mk}

# Services to migrate
SERVICES=(
    "plex"
    "radarr"
    "sonarr"
    "bazarr"
    "prowlarr"
    "sabnzbd"
    "transmission"
    "homepage"
)

# Verify connectivity
print_status "Verifying connectivity..."
if ssh -o ConnectTimeout=5 ${PHYSICAL_NAS_USER}@${PHYSICAL_NAS_IP} "echo 'Physical NAS OK'" &>/dev/null; then
    print_success "Connected to physical NAS"
else
    print_error "Cannot connect to physical NAS at ${PHYSICAL_NAS_IP}"
    exit 1
fi

if ssh -o ConnectTimeout=5 ${VM_USER}@${VM_IP} "echo 'VM OK'" &>/dev/null; then
    print_success "Connected to VM"
else
    print_error "Cannot connect to VM at ${VM_IP}"
    exit 1
fi

# Function to stop services
stop_services() {
    local host=$1
    local user=$2
    local location=$3
    
    print_status "Stopping services on $location..."
    for service in "${SERVICES[@]}"; do
        ssh ${user}@${host} "docker stop ${service} 2>/dev/null || true"
        print_success "Stopped ${service}"
    done
}

# Function to migrate Docker volumes
migrate_volumes() {
    print_status "Migrating Docker volumes..."
    
    for service in "${SERVICES[@]}"; do
        print_status "Migrating ${service}..."
        
        # Create directory on VM
        ssh ${VM_USER}@${VM_IP} "mkdir -p /home/${VM_USER}/docker/${service}"
        
        # Sync data using rsync
        rsync -avzP --delete \
            -e "ssh" \
            ${PHYSICAL_NAS_USER}@${PHYSICAL_NAS_IP}:/home/${PHYSICAL_NAS_USER}/docker/${service}/ \
            ${VM_USER}@${VM_IP}:/home/${VM_USER}/docker/${service}/
        
        print_success "${service} migrated"
    done
}

# Function to backup configurations
backup_configs() {
    print_status "Backing up configurations..."
    
    # Create backup directory
    BACKUP_DIR="ansible-nas-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p ${BACKUP_DIR}
    
    # Backup docker-compose files
    scp ${PHYSICAL_NAS_USER}@${PHYSICAL_NAS_IP}:/home/${PHYSICAL_NAS_USER}/docker/docker-compose.yml \
        ${BACKUP_DIR}/docker-compose.yml 2>/dev/null || true
    
    # Backup Traefik configuration
    scp -r ${PHYSICAL_NAS_USER}@${PHYSICAL_NAS_IP}:/home/${PHYSICAL_NAS_USER}/docker/traefik \
        ${BACKUP_DIR}/ 2>/dev/null || true
    
    print_success "Configurations backed up to ${BACKUP_DIR}"
}

# Main migration menu
echo ""
echo "========================================="
echo "Migration Options"
echo "========================================="
echo "1. Full Migration (Stop services, migrate data, update DNS)"
echo "2. Data Migration Only (Copy docker volumes)"
echo "3. Test Migration (Dry run, no changes)"
echo "4. Service by Service Migration"
echo "5. Exit"
echo ""
read -p "Select option [1-5]: " OPTION

case $OPTION in
    1)
        # Full Migration
        print_status "Starting full migration..."
        
        # Step 1: Stop services on physical NAS
        print_warning "This will stop all services on the physical NAS"
        read -p "Continue? (y/n): " CONFIRM
        if [[ $CONFIRM == "y" ]]; then
            stop_services ${PHYSICAL_NAS_IP} ${PHYSICAL_NAS_USER} "physical NAS"
            
            # Step 2: Backup configurations
            backup_configs
            
            # Step 3: Migrate volumes
            migrate_volumes
            
            # Step 4: Update permissions on VM
            print_status "Updating permissions on VM..."
            ssh ${VM_USER}@${VM_IP} "sudo chown -R ${VM_USER}:${VM_USER} /home/${VM_USER}/docker"
            print_success "Permissions updated"
            
            # Step 5: Deploy services on VM
            print_status "Ready to deploy services on VM"
            echo ""
            print_warning "Next steps:"
            echo "1. SSH to VM: ssh ${VM_USER}@${VM_IP}"
            echo "2. Navigate to Ansible-NAS: cd ~/ansible-nas"
            echo "3. Update inventory: vim inventories/vm/group_vars/nas/main.yml"
            echo "4. Deploy services: ansible-playbook -i inventories/vm/inventory nas.yml"
            echo "5. Update DNS records to point to ${VM_IP}"
        fi
        ;;
        
    2)
        # Data Migration Only
        print_status "Starting data migration..."
        migrate_volumes
        print_success "Data migration complete"
        ;;
        
    3)
        # Test Migration
        print_status "Running test migration (dry run)..."
        
        for service in "${SERVICES[@]}"; do
            print_status "Testing ${service}..."
            
            # Test rsync without actually copying
            rsync -avzPn \
                -e "ssh" \
                ${PHYSICAL_NAS_USER}@${PHYSICAL_NAS_IP}:/home/${PHYSICAL_NAS_USER}/docker/${service}/ \
                ${VM_USER}@${VM_IP}:/home/${VM_USER}/docker/${service}/ | head -20
            
            print_success "${service} test complete"
        done
        ;;
        
    4)
        # Service by Service
        print_status "Service by Service Migration"
        echo ""
        echo "Available services:"
        for i in "${!SERVICES[@]}"; do
            echo "$((i+1)). ${SERVICES[$i]}"
        done
        echo ""
        read -p "Select service to migrate [1-${#SERVICES[@]}]: " SERVICE_NUM
        
        if [[ $SERVICE_NUM -ge 1 && $SERVICE_NUM -le ${#SERVICES[@]} ]]; then
            SERVICE=${SERVICES[$((SERVICE_NUM-1))]}
            
            print_status "Migrating ${SERVICE}..."
            
            # Stop service on physical NAS
            ssh ${PHYSICAL_NAS_USER}@${PHYSICAL_NAS_IP} "docker stop ${SERVICE} 2>/dev/null || true"
            
            # Create directory and migrate
            ssh ${VM_USER}@${VM_IP} "mkdir -p /home/${VM_USER}/docker/${SERVICE}"
            rsync -avzP --delete \
                -e "ssh" \
                ${PHYSICAL_NAS_USER}@${PHYSICAL_NAS_IP}:/home/${PHYSICAL_NAS_USER}/docker/${SERVICE}/ \
                ${VM_USER}@${VM_IP}:/home/${VM_USER}/docker/${SERVICE}/
            
            # Update permissions
            ssh ${VM_USER}@${VM_IP} "sudo chown -R ${VM_USER}:${VM_USER} /home/${VM_USER}/docker/${SERVICE}"
            
            print_success "${SERVICE} migrated successfully"
            echo ""
            print_warning "Deploy ${SERVICE} on VM using:"
            echo "ansible-playbook -i inventories/vm/inventory nas.yml --tags \"${SERVICE}\""
        else
            print_error "Invalid selection"
        fi
        ;;
        
    5)
        echo "Exiting..."
        exit 0
        ;;
        
    *)
        print_error "Invalid option"
        exit 1
        ;;
esac

echo ""
print_success "Migration process completed!"
echo ""
echo "========================================="
echo "Post-Migration Checklist:"
echo "========================================="
echo "□ Services deployed on VM"
echo "□ Services accessible via local IP"
echo "□ DNS records updated to VM IP"
echo "□ Cloudflare tunnel reconfigured (if using)"
echo "□ NFS mounts verified on VM"
echo "□ Plex library scan completed"
echo "□ Download clients tested"
echo "□ Backup of physical NAS created"
echo "========================================="