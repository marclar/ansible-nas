# Migration Guide: VM to Standalone Ubuntu PC

This guide helps you migrate your Ansible-NAS deployment from a VM to a standalone Ubuntu PC.

## Pre-Migration Checklist

- [ ] Ubuntu 22.04 LTS (or newer) installed on standalone PC
- [ ] Static IP configured on the Ubuntu PC
- [ ] SSH access configured
- [ ] Docker and Docker Compose installed
- [ ] Python 3 and pip installed
- [ ] NFS client utilities installed (`sudo apt install nfs-common`)

## Migration Steps

### 1. Prepare the Standalone PC

On your new Ubuntu PC:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3 python3-pip git nfs-common

# Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Create necessary directories
sudo mkdir -p /mnt/truenas-media
mkdir -p ~/docker
```

### 2. Configure Network Settings

1. **Set a static IP** on your Ubuntu PC (recommended):
   ```bash
   # Use the configure-static-ip.sh script from the repo
   # Update DESIRED_IP to your preferred IP
   ```

2. **Update the standalone inventory** (`inventories/standalone/group_vars/nas/network.yml`):
   ```yaml
   # Update these values for your network:
   ansible_nas_server_ip: "192.168.1.100"  # Your Ubuntu PC's IP
   local_network_subnet: "192.168.1.0/24"  # Your network subnet
   truenas_server_ip: "192.168.1.227"     # Your TrueNAS IP (if changed)
   ```

3. **Update inventory host** (`inventories/standalone/inventory`):
   ```ini
   [nas]
   standalone ansible_host=192.168.1.100 ansible_user=your_username
   ```

### 3. Mount NFS Storage

Configure NFS mount on the standalone PC:

```bash
# Test NFS mount
sudo mount -t nfs TRUENAS_IP:/mnt/pool0/media /mnt/truenas-media

# If successful, make permanent
echo "TRUENAS_IP:/mnt/pool0/media /mnt/truenas-media nfs defaults 0 0" | sudo tee -a /etc/fstab
```

### 4. Copy Configuration Files

1. **Copy vault file** (contains encrypted passwords):
   ```bash
   cp inventories/production/group_vars/nas/vault.yml inventories/standalone/group_vars/nas/vault.yml
   ```

2. **Copy .vault_pass file** (vault password):
   ```bash
   # Make sure .vault_pass exists in the root directory
   ```

### 5. Migrate Docker Data (Optional)

If you want to preserve data from your VM:

```bash
# On the VM, backup Docker data
tar czf docker-backup.tar.gz -C /home/mk docker/

# Transfer to standalone PC
scp docker-backup.tar.gz user@STANDALONE_IP:~/

# On standalone PC, extract
tar xzf docker-backup.tar.gz -C ~/
```

### 6. Update Cloudflare Tunnel

If using Cloudflare Tunnel for external access:

1. Update the tunnel configuration in Cloudflare dashboard
2. Point to the new standalone PC's IP
3. Or create a new tunnel for the standalone PC

### 7. Deploy to Standalone PC

Run the deployment:

```bash
# Use the standalone deployment script
./deploy-standalone.sh

# Or manually:
ansible-playbook -i inventories/standalone/inventory nas.yml --vault-password-file .vault_pass
```

## IP Address Variable Reference

All hard-coded IPs have been replaced with variables:

| Old Hard-coded Value | New Variable | Location |
|---------------------|--------------|----------|
| 192.168.12.100 | `ansible_nas_server_ip` | network.yml |
| 192.168.12.226 | `truenas_server_ip` | network.yml |
| 192.168.12.0/24 | `local_network_subnet` | network.yml |

## Service URLs After Migration

Update your bookmarks with the new IP:

- Homepage: `http://[NEW_IP]:11111`
- Plex: `http://[NEW_IP]:32400/web`
- Traefik: `http://[NEW_IP]:8083`
- Portainer: `http://[NEW_IP]:9000`

External URLs (via Cloudflare) remain the same:
- https://home.1815.space
- https://plex.1815.space
- etc.

## Troubleshooting

### Cannot connect to standalone PC
- Verify IP address: `ip addr show`
- Check SSH: `sudo systemctl status ssh`
- Verify firewall: `sudo ufw status`

### NFS mount fails
- Check TrueNAS IP is reachable: `ping TRUENAS_IP`
- Verify NFS exports: `showmount -e TRUENAS_IP`
- Check permissions on TrueNAS

### Services not accessible
- Check Docker is running: `docker ps`
- Verify Traefik is routing correctly
- Check service logs: `docker logs [container_name]`

### Different network subnet
- Update `local_network_subnet` in network.yml
- Update Gluetun firewall rules if using VPN
- Ensure all IPs are on the same subnet

## Rollback Plan

If you need to switch back to the VM:

1. Keep the VM shutdown but not deleted
2. Use production inventory: `-i inventories/production/inventory`
3. Start VM and verify services
4. Update Cloudflare Tunnel back to VM IP

## Post-Migration

After successful migration:

1. Update documentation with new IP addresses
2. Test all services thoroughly
3. Update any external monitoring
4. Consider removing the VM inventory once stable
5. Update backup procedures for the standalone PC