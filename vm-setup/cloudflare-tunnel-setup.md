# Cloudflare Tunnel Configuration for Ansible-NAS VM

## Overview
With Cloudflare Tunnel + Traefik, all traffic flows through a single tunnel to Traefik, which then routes to the appropriate service based on the hostname.

```
Internet → Cloudflare → Tunnel → Traefik (port 80) → Services
```

## Step 1: Deploy Services First

Make sure your services are deployed:
```bash
cd /Users/mk/ansible-nas
./deploy-vm.sh
```

## Step 2: Configure Tunnel in Cloudflare Dashboard

1. Go to: https://one.dash.cloudflare.com/
2. Navigate to: Networks → Tunnels
3. Find your tunnel: `ansible-nas-vm`
4. Click "Configure" → "Public Hostname"

## Step 3: Add Public Hostnames

Add the following routes, ALL pointing to Traefik on port 80:

| Subdomain | Domain | Service Type | URL |
|-----------|--------|--------------|-----|
| home | 1815.space | HTTP | localhost:80 |
| plex | 1815.space | HTTP | localhost:80 |
| radarr | 1815.space | HTTP | localhost:80 |
| sonarr | 1815.space | HTTP | localhost:80 |
| bazarr | 1815.space | HTTP | localhost:80 |
| prowlarr | 1815.space | HTTP | localhost:80 |
| overseerr | 1815.space | HTTP | localhost:80 |
| transmission | 1815.space | HTTP | localhost:80 |
| sabnzbd | 1815.space | HTTP | localhost:80 |
| portainer | 1815.space | HTTP | localhost:80 |

**Important:** 
- ALL services point to `localhost:80` (Traefik)
- Do NOT use individual service ports
- Traefik will handle routing based on the hostname

## Step 4: How It Works

1. User visits `https://plex.1815.space`
2. Cloudflare routes through tunnel to your VM
3. Tunnel sends request to Traefik on port 80
4. Traefik sees hostname `plex.1815.space`
5. Traefik routes to Plex container on port 32400

## Step 5: Verify Traefik Configuration

Traefik should already be configured with routing rules for each service. Check by visiting:
- http://home.1815.space:8080 (Traefik dashboard)

You should see routers for each service based on hostname.

## Step 6: Test Access

After configuring the tunnel, test each service:
- https://home.1815.space - Homepage dashboard
- https://plex.1815.space - Plex
- https://radarr.1815.space - Radarr
- etc.

## Alternative: Single Wildcard Route

Instead of adding each subdomain individually, you can use a wildcard:

| Subdomain | Domain | Service Type | URL |
|-----------|--------|--------------|-----|
| * | 1815.space | HTTP | localhost:80 |

This routes ALL subdomains to Traefik, which is simpler but less secure.

## Troubleshooting

If a service isn't accessible:

1. Check Traefik dashboard for the router
2. Verify the service is running: `docker ps`
3. Check Traefik logs: `docker logs traefik`
4. Ensure the service has Traefik labels configured

## Security Notes

- The tunnel provides encryption from internet to your VM
- No ports need to be opened on your router
- Cloudflare Access can be added for authentication
- Services are not directly exposed to the internet