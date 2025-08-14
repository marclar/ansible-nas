# Cloudflare Tunnel

Cloudflare Tunnel creates secure outbound connections from your Ansible-NAS server to Cloudflare's edge, enabling public access to your applications without port forwarding. This is ideal for networks where port forwarding isn't possible (like mobile hotspots).

## Requirements

- Cloudflare account with domain configured
- Cloudflare Zero Trust account (free)

## Setup Instructions

### 1. Create Cloudflare Tunnel

1. Go to [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/)
2. Navigate to **Access** > **Tunnels**
3. Click **Create a tunnel**
4. Choose **Cloudflared** as the connector
5. Give your tunnel a name (e.g., "ansible-nas")
6. Copy the tunnel token that's displayed

### 2. Configure DNS

For each application you want to expose, create DNS records in Cloudflare:

- **Type**: CNAME  
- **Name**: `home` (for Homepage), `plex`, `radarr`, etc.
- **Target**: `<tunnel-id>.cfargotunnel.com`
- **Proxy status**: Proxied (orange cloud)

### 3. Configure Public Hostnames

In the Cloudflare Zero Trust dashboard:

1. Go to your tunnel settings
2. Click **Public Hostnames** tab
3. Add routes for each subdomain:
   - **Subdomain**: `home`
   - **Domain**: `1815.space` 
   - **Service**: `http://localhost:80` (Traefik HTTP port)

Repeat for other applications you want to expose.

### 4. Ansible Configuration

Add to your `inventories/<inventory>/group_vars/nas.yml`:

```yaml
# Enable Cloudflare Tunnel
cloudflare_tunnel_enabled: true
cloudflare_tunnel_token: "your_tunnel_token_here"

# Enable Traefik for reverse proxy
traefik_enabled: true

# Set your domain
ansible_nas_domain: "1815.space"
ansible_nas_email: "your_email@example.com"

# Enable applications for external access
homepage_enabled: true
homepage_available_externally: true
```

### 5. Deploy

Run the playbook to deploy Cloudflare Tunnel:

```bash
ansible-playbook -i inventories/your_inventory/inventory nas.yml --tags "cloudflare_tunnel,traefik,homepage"
```

## How It Works

1. **Cloudflare Tunnel** creates an encrypted connection from your server to Cloudflare
2. **Traefik** receives requests from the tunnel and routes them to the correct application
3. **Applications** are accessible via `https://app.yourdomain.com`

## Security Notes

- All traffic is encrypted end-to-end
- No inbound ports need to be opened on your network
- Applications should still use authentication where possible
- Consider enabling Cloudflare Access for additional security

## Troubleshooting

### Check tunnel status:
```bash
docker logs cloudflare-tunnel
```

### Verify tunnel connection:
- Check Cloudflare Zero Trust dashboard for tunnel status
- Ensure DNS records are properly configured
- Verify Traefik is running and accessible on port 80/443

### Common issues:
- **Token expired**: Generate a new token from Cloudflare dashboard
- **DNS not resolving**: Ensure CNAME records point to correct tunnel ID
- **503 errors**: Check that Traefik and applications are running locally