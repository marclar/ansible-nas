# VM Setup Instructions for Ansible-NAS

## Quick Setup (30 minutes)

### 1. Download Ubuntu Server ISO
```bash
cd ~/Downloads
curl -O https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
```

### 2. Install VM Software

**For Intel iMac:** Download VMware Fusion Player (free)
https://www.vmware.com/products/fusion/fusion-evaluation.html

**For Apple Silicon iMac:** Download UTM (free)
https://mac.getutm.app/

### 3. Create VM with These Settings
- **Name:** Ubuntu-NAS
- **RAM:** 8GB (8192 MB)
- **CPU:** 4 cores
- **Disk:** 100GB
- **Network:** Bridged mode

### 4. Install Ubuntu Server
During installation:
- Hostname: `ansible-nas-vm`
- Username: `mk`
- Password: (your choice)
- ✅ Install OpenSSH Server
- ❌ Skip snaps
- Use entire disk

### 5. Run Setup Script
After Ubuntu is installed:
```bash
# SSH into VM (find IP with: ip addr show)
ssh mk@<vm-ip>

# Download and run setup script
curl -O https://raw.githubusercontent.com/davestephens/ansible-nas/main/vm-setup/ubuntu-setup.sh
# Or copy from this repo:
scp /Users/mk/ansible-nas/vm-setup/ubuntu-setup.sh mk@<vm-ip>:~/

chmod +x ubuntu-setup.sh
./ubuntu-setup.sh
```

### 6. Configure Ansible-NAS
```bash
cd ~/ansible-nas

# Copy VM inventory from your Mac
scp -r mk@<your-mac>:/Users/mk/ansible-nas/inventories/vm inventories/

# Edit configuration
nano inventories/vm/group_vars/nas/main.yml
# Update ansible_nas_ip with your VM's IP
```

### 7. Deploy Services
```bash
# Install Ansible requirements
ansible-galaxy install -r requirements.yml

# Deploy all services
ansible-playbook -i inventories/vm/inventory nas.yml

# Or deploy specific services
ansible-playbook -i inventories/vm/inventory nas.yml --tags "plex,homepage"
```

### 8. Migrate Data (Optional)
From your Mac:
```bash
cd /Users/mk/ansible-nas/vm-setup
chmod +x migrate-to-vm.sh
./migrate-to-vm.sh
```

### 9. Set Up Auto-Start (Optional)
```bash
# Copy and edit the plist file
cp vm-autostart.plist ~/Library/LaunchAgents/
nano ~/Library/LaunchAgents/vm-autostart.plist
# Update with your VM software paths

# Load it
launchctl load ~/Library/LaunchAgents/vm-autostart.plist
```

## Verification Checklist

- [ ] VM running and accessible via SSH
- [ ] Docker installed and working (`docker ps`)
- [ ] NFS mount connected (`df -h | grep truenas`)
- [ ] Services deployed (`docker ps` shows containers)
- [ ] Homepage accessible at http://<vm-ip>:11111
- [ ] Plex accessible at http://<vm-ip>:32400/web

## Performance Comparison

| Task | Physical NAS | VM on iMac | Improvement |
|------|-------------|------------|-------------|
| AV1 1080p Transcode | Cannot handle | Smooth | ✅ Fixed |
| 4K HEVC → 1080p | 0.3x speed | 2-3x speed | 10x faster |
| Concurrent Streams | 1 max | 3-4 | 3-4x capacity |
| CPU Benchmark | ~500 | ~5000-8000 | 10-16x faster |

## Troubleshooting

### VM Won't Start
- Check VM software is installed
- Verify enough free disk space (100GB+)
- Ensure virtualization enabled in BIOS

### Can't Connect to VM
- Check VM network is in bridged mode
- Verify VM has IP: `ip addr show`
- Check firewall: `sudo ufw status`

### NFS Mount Failed
- Verify TrueNAS IP is correct
- Check NFS export settings on TrueNAS
- Test mount manually: `sudo mount -t nfs 192.168.12.227:/mnt/pool0/media /mnt/test`

### Services Not Accessible
- Check Docker is running: `systemctl status docker`
- Verify containers are up: `docker ps`
- Check Traefik logs: `docker logs traefik`

## Support

For issues or questions:
1. Check Ansible-NAS docs: https://ansible-nas.io
2. Review logs: `docker logs <container-name>`
3. Check system resources: `htop`