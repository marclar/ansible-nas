# Remove Service Command

This command helps you safely remove/uninstall a service from Ansible-NAS.

## Usage
```
/remove-service <service-name>
```

## Steps to Remove a Service

### 1. Stop and Remove Container
First, stop and remove the Docker container:
```bash
ssh mk@192.168.12.100 "docker stop {service} && docker rm {service}"
```

For services with multiple containers (e.g., with database):
```bash
ssh mk@192.168.12.100 "docker stop {service} {service}-db && docker rm {service} {service}-db"
```

### 2. Disable the Service in Configuration
Update your inventory file `inventories/vm/group_vars/nas/main.yml`:

```yaml
# Disable the service
{service}_enabled: false
{service}_available_externally: false
```

**Note**: Don't remove the configuration lines entirely - just set to `false`. This preserves settings if you want to re-enable later.

### 3. Remove from Homepage Widget Configuration
In `inventories/vm/group_vars/nas/main.yml`, remove or comment out the service from `homepage_services_yaml`:

```yaml
homepage_services_yaml:
  - Category Name:
      # - {Service}:  # Commented out or removed
      #     icon: {service}
      #     href: https://{service}.{{ ansible_nas_domain }}
      #     description: Service description
      #     widget:
      #       type: {service}
      #       url: http://192.168.12.100:{port}
      #       key: "{{ vault_{service}_api_key }}"
```

### 4. Remove from Traefik Manual Services (if applicable)
If the service was manually added to Traefik configuration:

```bash
# Check if service is in manual-services.toml
ssh mk@192.168.12.100 "grep -i {service} /home/mk/docker/traefik/manual-services.toml"

# If found, edit the file to remove the service sections
ssh mk@192.168.12.100 "sudo nano /home/mk/docker/traefik/manual-services.toml"

# Restart Traefik to apply changes
ssh mk@192.168.12.100 "docker restart traefik"
```

### 5. Clean Up Data Directory (Optional)
**WARNING**: This will permanently delete all service data!

To preserve data for potential reinstallation:
```bash
# Just rename the directory
ssh mk@192.168.12.100 "sudo mv /opt/{service} /opt/{service}.backup.$(date +%Y%m%d)"
```

To completely remove data:
```bash
# Permanently delete all service data
ssh mk@192.168.12.100 "sudo rm -rf /opt/{service}"
```

### 6. Remove Docker Images (Optional)
To free up disk space:
```bash
# List images related to the service
ssh mk@192.168.12.100 "docker images | grep {service}"

# Remove the image(s)
ssh mk@192.168.12.100 "docker rmi {image_name}:{tag}"
```

### 7. Clean Up Vault Entries (Optional)
If the service had API keys or passwords in vault:

1. Decrypt the vault:
```bash
ansible-vault decrypt inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

2. Remove or comment out the service entries:
```yaml
# vault_{service}_api_key: "your-api-key-here"  # Commented out
```

3. Re-encrypt the vault:
```bash
ansible-vault encrypt inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

### 8. Redeploy Homepage (if widgets were removed)
Update Homepage to reflect the changes:
```bash
ansible-playbook -i inventories/vm/inventory nas.yml --tags "homepage" --vault-password-file .vault_pass
```

### 9. Verify Removal
Check that the service is completely removed:
```bash
# Container should not exist
ssh mk@192.168.12.100 "docker ps -a | grep {service}"

# Service URL should return 404 or connection error
curl -L -s -o /dev/null -w "%{http_code}" "https://{service}.1815.space"

# Check Homepage doesn't show the service
```

### 10. Remove any custom scripts
If any custom Bash, Python, or MD scripts and instructions were created, remove them.

### 11. Document the Removal
Update `/Users/mk/ansible-nas/CLAUDE.md` to reflect that the service has been removed.

## Special Cases

### VPN-Routed Services (Transmission, SABnzbd)
These services use Gluetun's network, so they don't have their own container network to clean up. Just stop/remove the container and clean data.

### Services with Databases
Some services have separate database containers:
```bash
# Example for LinkAce with MariaDB
ssh mk@192.168.12.100 "docker stop linkace linkace-db && docker rm linkace linkace-db"
ssh mk@192.168.12.100 "sudo rm -rf /opt/linkace /opt/linkace-db"
```

### Services Using Shared Networks
If a service created a custom Docker network:
```bash
# List networks
ssh mk@192.168.12.100 "docker network ls"

# Remove unused network
ssh mk@192.168.12.100 "docker network rm {network_name}"
```

### Services with Persistent Volumes
Some services create Docker volumes instead of bind mounts:
```bash
# List volumes
ssh mk@192.168.12.100 "docker volume ls"

# Remove volume
ssh mk@192.168.12.100 "docker volume rm {volume_name}"
```

## Rollback/Re-enable a Service
If you need to re-enable a service that was disabled (not deleted):

1. Set `{service}_enabled: true` in main.yml
2. Redeploy with Ansible:
```bash
ansible-playbook -i inventories/vm/inventory nas.yml --tags "{service}" --vault-password-file .vault_pass
```

## Complete Removal Checklist
- [ ] Container stopped and removed
- [ ] Service disabled in main.yml
- [ ] Homepage widget configuration removed/commented
- [ ] Traefik manual services cleaned (if applicable)
- [ ] Data directory backed up or removed
- [ ] Docker images removed (optional)
- [ ] Vault entries cleaned (optional)
- [ ] Homepage redeployed
- [ ] Removal verified
- [ ] Scripts and/or Markdown removed
- [ ] Documentation updated

## Example: Removing LinkAce

```bash
# 1. Stop and remove container
ssh mk@192.168.12.100 "docker stop linkace && docker rm linkace"

# 2. Disable in inventories/vm/group_vars/nas/main.yml:
linkace_enabled: false
linkace_available_externally: false

# 3. Remove from homepage_services_yaml in main.yml

# 4. Remove from Traefik manual services
ssh mk@192.168.12.100 "sudo nano /home/mk/docker/traefik/manual-services.toml"
# Remove LinkAce sections
ssh mk@192.168.12.100 "docker restart traefik"

# 5. Backup data
ssh mk@192.168.12.100 "sudo mv /opt/linkace /opt/linkace.backup.$(date +%Y%m%d)"

# 6. Remove image (optional)
ssh mk@192.168.12.100 "docker rmi linkace/linkace:v1.14.0-simple"

# 7. Redeploy Homepage
ansible-playbook -i inventories/vm/inventory nas.yml --tags "homepage" --vault-password-file .vault_pass

# 8. Verify
ssh mk@192.168.12.100 "docker ps | grep linkace"  # Should return nothing
curl -L -s -o /dev/null -w "%{http_code}" "https://linkace.1815.space"  # Should return 404
```

## Safety Notes
- Always backup data before removal
- Consider disabling services before complete removal
- Keep configuration in main.yml (set to false) for easy re-enabling
- Document what was removed and when
- Test in non-production first if possible