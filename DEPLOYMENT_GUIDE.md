# Ansible-NAS Fresh Deployment Guide

This guide ensures you can deploy Ansible-NAS to a brand-new VM without manual configuration fixes.

## Prerequisites

1. **Target VM Requirements:**
   - Ubuntu Server 22.04 LTS
   - Minimum 8GB RAM, 100GB storage
   - Static IP address configured
   - SSH access enabled

2. **NFS Storage (if using TrueNAS):**
   - TrueNAS server at 192.168.12.226 (or update in configuration)
   - NFS share exported at `/mnt/pool0/media`
   - Proper permissions set for the media directories

## Step 1: Initial Configuration

### 1.1 Update Server IP
Edit `inventories/production/inventory`:
```bash
[nas]
192.168.12.100 ansible_user=mk  # Change IP to your server
```

### 1.2 Update Variables
Edit `inventories/production/group_vars/nas/main.yml`:
```yaml
# Server IP Configuration
ansible_nas_server_ip: "192.168.12.100"  # Your server IP

# Update your domain
ansible_nas_domain: "1815.space"  # Your domain

# Update NFS mount if different
nfs_mount_point: "/mnt/truenas-media"
```

### 1.3 Set Vault Password
Create `.vault_pass` file:
```bash
echo "your-secure-password" > .vault_pass
chmod 600 .vault_pass
```

## Step 2: Prepare NFS Storage

On the target server, create mount point and add to fstab:
```bash
ssh mk@192.168.12.100
sudo mkdir -p /mnt/truenas-media
sudo bash -c 'echo "192.168.12.226:/mnt/pool0/media /mnt/truenas-media nfs defaults 0 0" >> /etc/fstab'
sudo mount -a
```

Create required directories on NFS:
```bash
sudo mkdir -p /mnt/truenas-media/downloads/complete
sudo mkdir -p /mnt/truenas-media/downloads/incomplete
sudo mkdir -p /mnt/truenas-media/{movies,tv,music,photos,books,audiobooks,comics,podcasts,documents}
sudo chown -R mk:mk /mnt/truenas-media/downloads
```

## Step 3: Deploy Services

### 3.1 Full Deployment
```bash
./deploy.sh
# Select option 1: Deploy all services
```

### 3.2 Wait for Services to Initialize
Services need time to generate their configuration files and API keys:
```bash
# Wait about 2-3 minutes for services to fully start
sleep 180
```

## Step 4: Synchronize API Keys

**IMPORTANT:** This step is crucial for Homepage widgets to work correctly.

Run the post-deployment configuration script:
```bash
./post_deploy_config.sh
```

This script will:
1. Extract API keys from running services (Radarr, Sonarr, SABnzbd)
2. Update the vault with correct API keys
3. Redeploy Homepage with synchronized configuration

## Step 5: Configure Plex Token (Manual)

Plex requires manual token configuration:

1. Visit https://plex.1815.space (or http://192.168.12.100:32400)
2. Complete Plex setup wizard
3. Go to Settings → Your Account → Authorized Devices
4. Click "Get Token" or visit https://www.plex.tv/claim/
5. Update vault with token:

```bash
# Edit vault
ansible-vault edit inventories/production/group_vars/nas/vault.yml --vault-password-file=.vault_pass

# Update this line:
vault_plex_api_key: "YOUR_PLEX_TOKEN_HERE"
```

6. Redeploy Homepage:
```bash
ansible-playbook -i inventories/production/inventory nas.yml --tags "homepage"
```

## Step 6: Configure Cloudflare Tunnel (Optional)

If using Cloudflare Tunnel for external access:

1. Get tunnel token from Cloudflare dashboard
2. Update vault:
```bash
ansible-vault edit inventories/production/group_vars/nas/vault.yml --vault-password-file=.vault_pass
# Update: vault_cloudflare_tunnel_token: "YOUR_TOKEN"
```
3. Redeploy cloudflare-tunnel:
```bash
ansible-playbook -i inventories/production/inventory nas.yml --tags "cloudflare-tunnel"
```

## Verification Checklist

After deployment, verify everything works:

1. **Test API Connections:**
```bash
./test_homepage_apis.sh
```

2. **Check Homepage Dashboard:**
- Visit https://home.1815.space (or http://192.168.12.100:11111)
- All service widgets should display without errors

3. **Verify Services:**
- Plex: https://plex.1815.space
- Radarr: https://radarr.1815.space
- Sonarr: https://sonarr.1815.space
- SABnzbd: https://sabnzbd.1815.space
- Transmission: https://transmission.1815.space

## Troubleshooting

### Services Not Starting
```bash
# Check Docker containers
ssh mk@192.168.12.100 "docker ps -a"

# Check logs for specific service
ssh mk@192.168.12.100 "docker logs [service_name]"
```

### API Errors in Homepage
```bash
# Re-run API synchronization
./post_deploy_config.sh
```

### NFS Mount Issues
```bash
# Check mount
ssh mk@192.168.12.100 "df -h | grep truenas"

# Remount if needed
ssh mk@192.168.12.100 "sudo mount -a"
```

### Permission Issues
```bash
# Fix Docker directory permissions
ssh mk@192.168.12.100 "sudo chown -R mk:mk /home/mk/docker"

# Fix NFS permissions
ssh mk@192.168.12.100 "sudo chown -R mk:mk /mnt/truenas-media/downloads"
```

## Important Notes

1. **API Keys:** Services generate their own API keys on first run. The `post_deploy_config.sh` script must be run after initial deployment to synchronize these keys with Homepage.

2. **Persistent Configuration:** All configuration is stored in:
   - `inventories/production/group_vars/nas/main.yml` - Main configuration
   - `inventories/production/group_vars/nas/vault.yml` - Encrypted secrets
   - These files contain everything needed for reproducible deployments

3. **Backup:** Before redeploying to a new VM, backup:
   - `/home/mk/docker` directory from old server (contains service configurations)
   - The entire ansible-nas repository with your customizations

## Quick Redeploy Command

For subsequent deployments after initial setup:
```bash
# Full deployment with API sync
./deploy.sh && sleep 180 && ./post_deploy_config.sh
```

---
*Last Updated: August 24, 2025*