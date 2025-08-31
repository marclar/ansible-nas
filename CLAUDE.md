# Ansible-NAS Project State Summary

**Date:** August 31, 2025  
**Project:** Home Media Server using Ansible-NAS  
**Domain:** 1815.space  
**Infrastructure:** Physical server + TrueNAS NFS storage

## 🎯 Project Overview

This is a fully operational home media server deployment using Ansible-NAS, providing automated management of Docker-based media applications with secure remote access via Cloudflare Tunnel and local NFS storage integration.

Ansible-NAS is an Infrastructure as Code solution that replaces commercial NAS solutions like FreeNAS. It uses Ansible to automate the deployment and management of 100+ self-hosted applications on Ubuntu Server 22.04 LTS using Docker containers.

## 🏗️ Current Production Architecture

### **Core Infrastructure:**
- **Ansible Control Node:** MacOS (mk@MacBook)
- **Target Server:** Ubuntu 22.04 LTS (192.168.12.208)
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

### **Active Services (Currently Running):**

| Service | Status | URL | Port | Purpose |
|---------|--------|-----|------|---------| 
| **Homepage** | ✅ Running (healthy) | https://home.1815.space | 11111 | Dashboard & Service Directory |
| **Plex** | ✅ Running | https://plex.1815.space | 32400 | Media Server |
| **Radarr** | ✅ Running | https://radarr.1815.space | 7878 | Movie Collection Manager |
| **Sonarr** | ✅ Running | https://sonarr.1815.space | 8989 | TV Series Collection Manager |
| **Unmanic** | ✅ Running | https://unmanic.1815.space | 8889 | Automated Media Library Optimizer |
| **Cloudflare Tunnel** | ✅ Running | N/A | N/A | Secure Remote Access |

### **Service Health Status:**
- 6 Docker containers running
- External access working through Cloudflare Tunnel with Access authentication
- Local direct access available on all services
- Cloudflare tunnel successfully connected with 4 connections established

## 💾 Storage Configuration

### **NFS Mount Setup:**
```bash
Source: 192.168.12.227:/mnt/pool0/media
Mount: /mnt/truenas-media
Size: 8.6TB (738GB used, 91% available)
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

# Or direct Ansible commands (always use vault password file):
ansible-playbook -i inventories/production/inventory nas.yml --vault-password-file=.vault_pass
ansible-playbook -i inventories/production/inventory nas.yml --vault-password-file=.vault_pass --tags "homepage,plex"

# Deploy specific services by tag:
ansible-playbook -i inventories/production/inventory nas.yml --vault-password-file=.vault_pass --tags "radarr,sonarr"

# Check mode (dry run):
ansible-playbook -i inventories/production/inventory nas.yml --vault-password-file=.vault_pass --check
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

### **CREDENTIALS AND SECRETS MANAGEMENT**

#### **Ansible Vault Configuration:**
- **All secrets are stored in encrypted Ansible vault files**
- **Vault file location:** `inventories/production/group_vars/nas/vault.yml`
- **Vault password file:** `.vault_pass` (in project root, gitignored)
- **Never commit secrets in plain text** - always use the vault

#### **Managing Secrets:**
```bash
# View vault contents
ansible-vault view inventories/production/group_vars/nas/vault.yml --vault-password-file=.vault_pass

# Edit vault (opens in editor)
ansible-vault edit inventories/production/group_vars/nas/vault.yml --vault-password-file=.vault_pass

# Decrypt to temp file (for complex edits)
ansible-vault decrypt inventories/production/group_vars/nas/vault.yml --vault-password-file=.vault_pass --output=/tmp/vault.yml
# Edit the file, then re-encrypt:
ansible-vault encrypt /tmp/vault.yml --vault-password-file=.vault_pass --output=inventories/production/group_vars/nas/vault.yml
```

#### **Stored Secrets Include:**
- Cloudflare tunnel token
- Media server API keys (Plex, Radarr, Sonarr, SABnzbd)
- VPN credentials (if configured)
- Service-specific authentication tokens  

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
# Via hosts file (add to /etc/hosts):
192.168.12.208 home.1815.space plex.1815.space radarr.1815.space sonarr.1815.space unmanic.1815.space

# Direct port access:
http://192.168.12.208:11111  # Homepage
http://192.168.12.208:32400  # Plex
http://192.168.12.208:7878   # Radarr
http://192.168.12.208:8989   # Sonarr
http://192.168.12.208:8889   # Unmanic
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
ssh mk@192.168.12.208 "docker ps"

# View service logs
ssh mk@192.168.12.208 "docker logs {service_name}"

# Restart specific service
ssh mk@192.168.12.208 "docker restart {service_name}"

# Check NFS mount
ssh mk@192.168.12.208 "df -h | grep truenas"
```

## 📊 Current System Status

### **Resource Usage:**
- Docker containers: 6 running
- System load: Normal
- NFS storage: 91% available (8.6TB capacity, 738GB used)
- Network: Stable connectivity to both Cloudflare and TrueNAS

### **Recent Changes:**
- ✅ **Configured Unmanic service** in Homepage dashboard and Traefik routing (Aug 31, 2025)
- ✅ **Updated Homepage layout** with improved service organization (Aug 31, 2025)
- ✅ **Migrated to new physical server** (192.168.12.208) (Aug 30, 2025)
- ✅ **Updated Cloudflare tunnel token** and re-established secure connection (Aug 30, 2025)
- ✅ **Configured SSH key-only authentication** with password auth disabled (Aug 30, 2025)
- ✅ **Set up passwordless sudo** for automation user (Aug 30, 2025)
- ✅ Removed Tdarr distributed transcoding system (Aug 25, 2025)
- ✅ Installed Unmanic automated media library optimizer (Aug 25, 2025)
- ✅ Removed Organizr, Emby, YouTube-DL, and TiddlyWiki services (Aug 25, 2025)
- ✅ Removed LinkAce bookmark manager service (Aug 25, 2025)

## ✅ Project Status: **PRODUCTION READY**

The system is fully operational, properly configured, and ready for daily use. All troubleshooting artifacts have been cleaned up, and the deployment process is streamlined for future updates.

## Important Development Notes

- Target OS is Ubuntu Server 22.04 LTS only
- All applications run in Docker containers
- External access configured via Traefik with Let's Encrypt SSL
- Disk partitioning is not automated (manual setup required)
- Each role is independently configurable via tags

---
**Last Updated:** August 31, 2025  
**Maintained By:** mk  
**Deployment Status:** ✅ Active and Stable on Physical Server (192.168.12.208)
