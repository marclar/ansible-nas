# Install Service Command

This command helps you install and configure a new service in Ansible-NAS.

## Usage
```
/install-service <service-name>
```

## Steps to Install a Service

### 1. Enable the Service
Add the service configuration to your inventory file `inventories/vm/group_vars/nas/main.yml`:

```yaml
# Enable the service
{service}_enabled: true
{service}_available_externally: true  # If you want external access via Cloudflare
```

IMPORTANT: if there's no available role for the service, prefer creating a new role over creating a one-off installation script.

### 2. Configure Service-Specific Settings (if needed)
Some services require additional configuration. Check the role's defaults file:
```bash
cat roles/{service}/defaults/main.yml
```

Common configurations to add to `inventories/vm/group_vars/nas/main.yml`:
```yaml
# Example configurations
{service}_hostname: "{service}"  # Usually defaults to service name
{service}_port: "XXXX"  # Check the default port
{service}_data_directory: "{{ docker_home }}/{service}"
```

### 3. Add Homepage Widget Configuration (if applicable)
In `inventories/vm/group_vars/nas/main.yml`, update the `homepage_services_yaml` section:

```yaml
homepage_services_yaml:
  - Category Name:  # Choose appropriate category: Media Services, Media Management, Download Clients, System Management, etc.
      - {Service}:
          icon: {service}
          href: https://{service}.{{ ansible_nas_domain }}
          description: Service description
          widget:
            type: {service}  # If widget is supported
            url: http://192.168.12.100:{port}  # IMPORTANT: Use IP address, not Docker hostname
            key: "{{ vault_{service}_api_key }}"  # If API key is needed
```

**Important**: Always use `http://192.168.12.100:{port}` for widget URLs, not Docker service names.

### 4. Add API Key to Vault (if needed)
If the service requires an API key for the Homepage widget:

1. Decrypt the vault:
```bash
ansible-vault decrypt inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

2. Add the API key:
```yaml
vault_{service}_api_key: "your-api-key-here"
```

3. Re-encrypt the vault:
```bash
ansible-vault encrypt inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

### 5. Check if Service Uses VPN
If the service should route through VPN (like download clients):

```yaml
{service}_use_vpn: true  # Add to main.yml
```

The service will use the Gluetun container's network. You may need to:
- Add manual routing in Traefik
- Use different ports exposed by Gluetun

### 6. Deploy the Service
```bash
ansible-playbook -i inventories/vm/inventory nas.yml --tags "{service}" --vault-password-file .vault_pass
```

### 7. Verify Deployment
Check if the container is running:
```bash
ssh mk@192.168.12.100 "docker ps | grep {service}"
```

### 8. Test External Access
```bash
curl -L -s -o /dev/null -w "%{http_code}" "https://{service}.1815.space"
```

Should return 200, 301, 307, or similar (not 404 or 502).

### 9. Fix Common Issues

#### Service returns 404
Check if the service has proper Traefik labels:
```bash
ssh mk@192.168.12.100 "docker inspect {service} | grep -E 'traefik.enable|traefik.http.routers.*entrypoints'"
```

If missing `entrypoints`, edit `roles/{service}/tasks/main.yml` and ensure it has:
```yaml
labels:
  traefik.enable: "{{ {service}_available_externally | string }}"
  traefik.http.routers.{service}.rule: "Host(`{{ {service}_hostname }}.{{ ansible_nas_domain }}`)"
  traefik.http.routers.{service}.entrypoints: "web"
  traefik.http.services.{service}.loadbalancer.server.port: "{port}"
```

Remove any TLS configuration lines like:
- `traefik.http.routers.{service}.tls.certresolver`
- `traefik.http.routers.{service}.tls.domains`

#### Service returns 502 Bad Gateway
Check if the port in Traefik labels matches the actual service port:
```bash
ssh mk@192.168.12.100 "docker inspect {service} | grep loadbalancer.server.port"
```

#### Homepage Widget Shows "API Error"
1. Ensure widget URL uses IP: `http://192.168.12.100:{port}`
2. Verify API key is set in vault and referenced correctly
3. Check if service requires special configuration (like SABnzbd hostname whitelist)

### 10. Document the Installation
Update `/Users/mk/ansible-nas/CLAUDE.md` with the new service information.

## Example: Installing n8n

```bash
# 1. Add to inventories/vm/group_vars/nas/main.yml:
n8n_enabled: true
n8n_available_externally: true

# 2. Add to homepage_services_yaml in main.yml:
  - Automation:
      - n8n:
          icon: n8n
          href: https://n8n.1815.space
          description: Workflow Automation
          widget:
            type: customapi
            url: http://192.168.12.100:5678

# 3. Deploy:
ansible-playbook -i inventories/vm/inventory nas.yml --tags "n8n" --vault-password-file .vault_pass

# 4. Verify:
ssh mk@192.168.12.100 "docker ps | grep n8n"
curl -L -s -o /dev/null -w "%{http_code}" "https://n8n.1815.space"
```

## Services with Special Requirements

### VPN-Routed Services (Transmission, SABnzbd)
- Must set `{service}_use_vpn: true`
- Configure manual routing in Traefik templates
- Use Gluetun-exposed ports

### Services Requiring Host Network (Plex)
- May need special network_mode configuration
- Direct port access instead of Docker networking

### Services with Hostname Verification (SABnzbd)
- Add environment variables for HOST_WHITELIST
- May need to edit service config files post-deployment

## Checklist
- [ ] Service enabled in main.yml
- [ ] Service configured as available_externally (if needed)
- [ ] Homepage widget added with IP-based URL
- [ ] API key added to vault (if needed)
- [ ] Service deployed successfully
- [ ] External access verified
- [ ] Homepage widget working
- [ ] Documentation updated