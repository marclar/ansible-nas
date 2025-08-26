# Ansible-NAS Project State Summary

**Date:** August 14, 2025  
**Project:** Home Media Server using Ansible-NAS  
**Domain:** Configured in inventory  
**Infrastructure:** Local server + NFS storage

## 🎯 Project Overview

This is a fully operational home media server deployment using Ansible-NAS, providing automated management of Docker-based media applications with secure remote access via Cloudflare Tunnel and local NFS storage integration.

Ansible-NAS is an Infrastructure as Code solution that replaces commercial NAS solutions like FreeNAS. It uses Ansible to automate the deployment and management of 100+ self-hosted applications on Ubuntu Server 22.04 LTS using Docker containers.

## 🏗️ Current Production Architecture

### **Core Infrastructure:**
- **Ansible Control Node:** MacOS (mk@MacBook)
- **Target Server:** Ubuntu 22.04 LTS (192.168.12.100)
- **Storage Backend:** TrueNAS SCALE NFS (192.168.12.227) - 8.6TB capacity
- **Network Access:** Cloudflare Tunnel + Local network
- **Domain:** 1815.space with wildcard SSL certificates

### **Service Stack:**
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Client        │    │   Cloudflare    │    │   Home Server   │
│   Requests      │───▶│   Tunnel        │───▶│   (Traefik)     │
│                 │    │   Access Auth   │    │   Services      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                      │
                                               ┌─────────────────┐
                                               │   TrueNAS NFS   │
                                               │   Storage       │
                                               │   (8.6TB)       │
                                               └─────────────────┘
```

## 🚀 Current Deployed Services

### **Active Services (All Operational):**

| Service | Status | URL | Port | Purpose |
|---------|--------|-----|------|---------|
| **Homepage** | ✅ Running | https://home.1815.space | 11111 | Dashboard & Service Directory |
| **Plex** | ✅ Running | https://plex.1815.space | 32400 | Media Server |
| **Radarr** | ✅ Running | https://radarr.1815.space | 7878 | Movie Collection Manager |
| **Sonarr** | ✅ Running | https://sonarr.1815.space | 8989 | TV Series Collection Manager |
| **Bazarr** | ✅ Running | https://bazarr.1815.space | 6767 | Subtitle Manager |
| **Prowlarr** | ✅ Running | https://prowlarr.1815.space | 9696 | Indexer Manager |
| **SABnzbd** | ✅ Running | https://sabnzbd.1815.space | 18080 | Usenet Downloader |
| **Transmission** | ✅ Running | https://transmission.1815.space | 9092 | Torrent Client |
| **Unmanic** | ✅ Running | https://unmanic.1815.space | 8889 | Automated Media Library Optimizer |
| **Traefik** | ✅ Running | http://192.168.12.100:8083 | 8083 | Reverse Proxy & SSL |
| **Cloudflare Tunnel** | ✅ Running | N/A | N/A | Secure Remote Access |
| **Cloudflare DDNS** | ✅ Running | N/A | N/A | Dynamic DNS Updates |

### **Service Health Status:**
- All containers running without issues
- External access working through Cloudflare Tunnel
- Local direct access available on all services
- Homepage dashboard showing all services with working widgets

## 💾 Storage Configuration

### **NFS Mount Setup:**
```bash
Source: 192.168.12.227:/mnt/pool0/media
Mount: /mnt/truenas-media
Size: 8.6TB (7.2GB used, 99% available)
Type: NFSv3, auto-mounted via /etc/fstab
```

### **Directory Structure:**
```
/mnt/truenas-media/
├── downloads/          # Active download directory
│   ├── torrents/      # Transmission downloads
│   ├── sabnzbd/       # Usenet downloads
│   └── complete/      # Finished downloads
├── movies/            # Organized movie collection
├── tv/               # TV series organized by show
├── music/            # Audio content
├── photos/           # Photo collection
├── books/            # E-books
├── audiobooks/       # Audio book collection
├── comics/           # Comic collection
├── podcasts/         # Podcast episodes
└── documents/        # General documents
```

## 🔧 Production Deployment

### **Key Scripts:**
- **`deploy.sh`** - Main deployment script with multiple options:
  - Full deployment (all services)
  - Specific service deployment by tags  
  - Dry run mode
  - Configuration-only updates

### **Production Deployment:**
```bash
# Use the streamlined deployment script
./deploy.sh  # Interactive deployment with options

# Or direct Ansible commands:
ansible-playbook -i inventories/production/inventory nas.yml
ansible-playbook -i inventories/production/inventory nas.yml --tags "homepage,plex"
```

## Core Commands

### Development Setup
```bash
# Install Python development dependencies
pip install -r requirements-dev.txt

# Install Ansible collections and roles
ansible-galaxy install -r requirements.yml

# Run pre-commit hooks manually
pre-commit run --all-files
```

### Testing
```bash
# Run all role tests using Molecule
./tests/test.sh

# Test specific role
cd roles/[role-name]
molecule test

# Integration testing with Vagrant
./tests/test-vagrant.sh
```

### Deployment
```bash
# Deploy full stack
ansible-playbook -i inventories/[inventory-name]/inventory nas.yml

# Deploy specific applications
ansible-playbook -i inventories/[inventory-name]/inventory nas.yml --tags "plex,radarr,sonarr"

# Check what would be deployed (dry run)
ansible-playbook -i inventories/[inventory-name]/inventory nas.yml --check
```

### Documentation Development
```bash
# Start documentation development server
cd website/
npm start

# Build documentation
cd website/
npm run build
```

## Architecture

### Core Structure
- **nas.yml** - Main Ansible playbook orchestrating all roles
- **roles/** - 100+ application roles, each following standardized structure
- **group_vars/all.yml** - Global configuration defaults
- **inventories/** - Environment-specific configurations

### Role Structure
Each application role follows this pattern:
```
roles/[app-name]/
├── defaults/main.yml      # Default variables
├── tasks/main.yml         # Installation tasks
├── templates/             # Configuration templates
├── molecule/              # Tests
└── README.md             # Documentation
```

### Configuration Hierarchy
1. Global defaults: `group_vars/all.yml`
2. Inventory overrides: `inventories/[name]/group_vars/nas.yml`
3. Role defaults: `roles/[app]/defaults/main.yml`

### Key Technologies
- **Ansible** - Automation framework
- **Docker** - Container runtime
- **Traefik** - Reverse proxy with automatic SSL
- **Ubuntu Server 22.04 LTS** - Target OS

## Development Workflow

### Adding New Applications
1. Use `roles/hello_world` as template
2. Follow existing role structure conventions
3. Include Molecule tests in `molecule/` directory
4. Add documentation to role README.md
5. Update main README.md with application listing

### Testing Requirements
- All roles must have Molecule tests
- Tests run automatically in CI/CD pipeline
- Use `molecule test` for individual role testing

### Configuration Patterns
- Enable/disable apps with `[app]_enabled: true/false`
- Follow naming convention: `ansible_nas_[setting]`
- Docker containers use host networking or Traefik labels
- Persistent data stored in `ansible_nas_data_directory`

## Key Files

- **nas.yml:1-50** - Main playbook with role orchestration
- **group_vars/all.yml** - Global configuration (not included but referenced)
- **requirements.yml** - External Ansible dependencies
- **ansible.cfg:1-10** - Ansible configuration with fact caching
- **requirements-dev.txt:1-5** - Python development dependencies

## 🔐 Security Configuration

### **CREDENTIALS AND SECRETS**
- IMPORTANT: Keep api keys, secrets, and other credentials within the Ansible vault.  

### **Access Control:**
- **Remote Access:** Cloudflare Access authentication required
- **Local Access:** No authentication (trusted network)
- **SSL Certificates:** Wildcard cert for *.1815.space (auto-renewed)
- **Network:** Services isolated in Docker network

### **Authentication Details:**
- Cloudflare tunnel provides secure access without port forwarding
- Basic Auth available but currently disabled for better UX
- All data stored on local NFS with proper permissions

## 🌐 Network Access

### **External URLs (Cloudflare Tunnel):**
- All services accessible via https://{service}.1815.space
- Requires Cloudflare Access authentication
- Automatic SSL/TLS encryption

### **Local Network Access:**
```bash
# Via Traefik (add to /etc/hosts):
192.168.12.100 home.1815.space plex.1815.space radarr.1815.space sonarr.1815.space

# Direct port access:
http://192.168.12.100:11111  # Homepage
http://192.168.12.100:32400  # Plex
http://192.168.12.100:7878   # Radarr
# ... etc (see service table above)
```

## 🔄 Maintenance Procedures

### **Regular Tasks:**
1. **Update Services:** Run `./deploy.sh` and select full deployment
2. **Check Service Health:** Visit https://home.1815.space dashboard
3. **Monitor Storage:** Check NFS mount status and available space
4. **SSL Certificate Renewal:** Handled automatically by Traefik

### **Troubleshooting:**
```bash
# Check service status
ssh mk@192.168.12.100 "docker ps"

# View service logs
ssh mk@192.168.12.100 "docker logs {service_name}"

# Restart specific service
ssh mk@192.168.12.100 "docker restart {service_name}"

# Check NFS mount
ssh mk@192.168.12.100 "df -h | grep truenas"
```

## 📊 Current System Status

### **Resource Usage:**
- Docker containers: 11 running
- System load: Normal
- NFS storage: 99% available (8.6TB capacity)
- Network: Stable connectivity to both Cloudflare and TrueNAS

### **Recent Changes:**
- ✅ Removed Tdarr distributed transcoding system (Aug 25, 2025)
- ✅ Installed Unmanic automated media library optimizer (Aug 25, 2025)
- ✅ Removed Organizr, Emby, YouTube-DL, and TiddlyWiki services (Aug 25, 2025)
- ✅ Removed LinkAce bookmark manager service (Aug 25, 2025)
- ✅ Cleaned up all troubleshooting scripts (Aug 7, 2025)
- ✅ Fixed SABnzbd hostname verification issues  
- ✅ Configured permanent Docker permissions solution
- ✅ Removed Cloudflare authentication for local access
- ✅ Established stable NFS mount configuration

## ✅ Project Status: **PRODUCTION READY**

The system is fully operational, properly configured, and ready for daily use. All troubleshooting artifacts have been cleaned up, and the deployment process is streamlined for future updates.

## Important Development Notes

- Target OS is Ubuntu Server 22.04 LTS only
- All applications run in Docker containers
- External access configured via Traefik with Let's Encrypt SSL
- Disk partitioning is not automated (manual setup required)
- Each role is independently configurable via tags

---
**Last Updated:** August 25, 2025  
**Maintained By:** mk  
**Deployment Status:** ✅ Active and Stable
