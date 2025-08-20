# Ubuntu VM Setup for Ansible-NAS on iMac

This guide will help you set up an Ubuntu VM on your iMac to run Ansible-NAS services while using your TrueNAS for storage.

## Why Use a VM?

- **10-20x more CPU power** than your current NAS
- Handle AV1/HEVC transcoding without issues
- Run multiple Plex streams simultaneously
- Keep your NAS dedicated to storage
- VM runs in background without interfering with macOS

## System Requirements

### Minimum (Light usage)
- 4 CPU cores total on iMac
- 8GB total RAM on iMac
- 100GB free disk space
- macOS 10.15 or newer

### Recommended (Heavy transcoding)
- 6+ CPU cores on iMac
- 16GB+ total RAM on iMac
- 200GB free disk space
- Gigabit ethernet connection

## VM Software Options

### 1. UTM (Recommended for Apple Silicon Macs)
- **Pros:** Native Apple Silicon support, free, efficient
- **Cons:** Newer, less documentation
- **Download:** https://mac.getutm.app/
- **Best for:** M1/M2/M3 iMacs

### 2. VMware Fusion Player (Recommended for Intel Macs)
- **Pros:** Professional grade, free for personal use, excellent performance
- **Cons:** Requires registration
- **Download:** https://www.vmware.com/products/fusion/fusion-evaluation.html
- **Best for:** Intel iMacs

### 3. VirtualBox (Alternative)
- **Pros:** Completely free, widely used
- **Cons:** Slower on Apple Silicon, more complex
- **Download:** https://www.virtualbox.org/
- **Best for:** Users familiar with VirtualBox

## Quick Start Guide

### Step 1: Download Ubuntu Server
```bash
# Download Ubuntu Server 22.04 LTS (no GUI needed)
curl -O https://releases.ubuntu.com/22.04/ubuntu-22.04.5-live-server-amd64.iso
```

### Step 2: Create VM

#### For UTM:
1. Open UTM
2. Create New VM → Virtualize
3. Select Linux → Ubuntu 22.04
4. Settings:
   - RAM: 8192 MB
   - CPU Cores: 4
   - Storage: 100 GB
   - Network: Bridged (en0)
5. Mount the Ubuntu ISO
6. Start VM and install Ubuntu Server

#### For VMware Fusion:
1. Open VMware Fusion
2. New → Create Custom VM
3. Select Linux → Ubuntu 64-bit
4. Settings:
   - RAM: 8 GB
   - Processors: 4 cores
   - Hard Disk: 100 GB
   - Network: Bridged (Autodetect)
5. Mount the Ubuntu ISO
6. Start VM and install Ubuntu Server

### Step 3: Ubuntu Installation
During installation:
- Choose "Ubuntu Server" (no desktop)
- Set hostname: `ansible-nas-vm`
- Create user: `mk` (or your preferred username)
- Enable OpenSSH server
- Skip snap packages
- Use entire disk for installation

### Step 4: Initial Configuration
After installation, SSH into your VM:
```bash
# Find VM IP address (run this in VM console)
ip addr show

# From your Mac terminal
ssh mk@<vm-ip-address>
```

## Network Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   TrueNAS       │────▶│   Ubuntu VM     │────▶│   Clients       │
│  192.168.12.227 │ NFS │  192.168.12.x   │     │  (Plex, etc)    │
│   (Storage)     │     │   (Services)    │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                              ↑
                        ┌─────────────────┐
                        │     iMac        │
                        │   (Host OS)     │
                        └─────────────────┘
```

## Resource Allocation

### Conservative (Minimal impact on macOS):
- CPU: 2 cores
- RAM: 4 GB
- Disk: 50 GB

### Balanced (Recommended):
- CPU: 4 cores
- RAM: 8 GB  
- Disk: 100 GB

### Performance (Heavy transcoding):
- CPU: 6 cores
- RAM: 16 GB
- Disk: 200 GB

## Background Operation

### UTM:
```bash
# Run headless (no GUI window)
utmctl start "Ubuntu Server" --headless
```

### VMware Fusion:
```bash
# Run headless
vmrun start "/path/to/vm.vmx" nogui
```

### Auto-start on Login:
1. Create Launch Agent in `~/Library/LaunchAgents/`
2. Configure to start VM at login
3. See `vm-autostart.plist` for example

## Performance Tuning

### VM Settings:
- Enable VT-x/AMD-V in VM settings
- Enable nested virtualization if available
- Use paravirtualized drivers when possible
- Allocate RAM in powers of 2 (4GB, 8GB, 16GB)

### Ubuntu Optimizations:
- Disable unnecessary services
- Use `nice` for background tasks
- Configure swappiness for containers
- Enable CPU frequency scaling

## Monitoring

Check VM resource usage:
```bash
# On macOS (host)
top -pid $(pgrep -f "vmware-vmx|QEMU|VirtualBox")

# In Ubuntu VM
htop
docker stats
```

## Troubleshooting

### High CPU Usage
- Reduce VM CPU cores
- Enable CPU limiting in VM settings
- Use `nice` for transcoding tasks

### Network Issues
- Ensure bridged networking is enabled
- Check firewall settings
- Verify VM has unique MAC address

### Storage Issues
- Verify NFS mounts are working
- Check VM disk space
- Monitor Docker volume usage

## Next Steps

1. [Configure Ubuntu VM](ubuntu-setup.md)
2. [Set up NFS mounts](nfs-setup.md)
3. [Deploy Ansible-NAS](ansible-deploy.md)
4. [Migrate services](migration-guide.md)