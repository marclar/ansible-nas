# Correct Cloudflare Tunnel Configuration

## Public Hostname Configuration in Cloudflare Dashboard

Add these routes in your Cloudflare Tunnel configuration:

| Subdomain | Domain | Service Type | URL |
|-----------|--------|--------------|-----|
| home | 1815.space | HTTPS | localhost:443 |
| plex | 1815.space | HTTP | localhost:80 |
| radarr | 1815.space | HTTP | localhost:80 |
| sonarr | 1815.space | HTTP | localhost:80 |
| bazarr | 1815.space | HTTP | localhost:80 |
| prowlarr | 1815.space | HTTP | localhost:80 |
| overseerr | 1815.space | HTTP | localhost:80 |
| transmission | 1815.space | HTTP | localhost:80 |
| sabnzbd | 1815.space | HTTP | localhost:80 |
| portainer | 1815.space | HTTP | localhost:80 |
| netdata | 1815.space | HTTP | localhost:80 |
| emby | 1815.space | HTTP | localhost:80 |
| jellyfin | 1815.space | HTTP | localhost:80 |
| nzbget | 1815.space | HTTP | localhost:80 |
| n8n | 1815.space | HTTP | localhost:80 |
| tiddlywiki | 1815.space | HTTP | localhost:80 |
| youtubedlmaterial | 1815.space | HTTP | localhost:80 |
| organizr | 1815.space | HTTP | localhost:80 |

## How This Configuration Works

1. **Homepage (home.1815.space)**:
   - Routes to `https://localhost:443`
   - Traefik serves Homepage with SSL certificate
   - This is the main dashboard/entry point

2. **All Other Services**:
   - Route to `http://localhost:80`
   - Traefik receives HTTP requests on port 80
   - Traefik examines the Host header (e.g., plex.1815.space)
   - Traefik routes to the appropriate container based on its labels

## Why This Configuration

- **No wildcard needed**: Each subdomain gets its own DNS record
- **Clean separation**: Homepage gets HTTPS directly, others go through HTTP to Traefik
- **Traefik handles internal routing**: Based on Docker container labels
- **Consistent with production setup**: Matches your existing physical NAS configuration

## DNS Records Created

When you add these routes, Cloudflare automatically creates CNAME records:
- `home.1815.space` → tunnel UUID
- `plex.1815.space` → tunnel UUID
- etc.

This ensures proper DNS resolution without needing wildcard records.