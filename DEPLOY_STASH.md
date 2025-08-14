# Deploy Stash Manually

Since there's a connectivity issue, here are the manual steps to deploy Stash:

## Option 1: Using Ansible (Recommended)

Run this command from the ansible-nas directory:

```bash
ansible-playbook -i inventories/production/inventory nas.yml --tags "stash"
```

## Option 2: Direct Docker Deployment

SSH into your server and run these commands:

```bash
# 1. Create directories
mkdir -p /home/mk/docker/stash/{config,media,metadata,cache,generated}

# 2. Pull the image
docker pull stashapp/stash:latest

# 3. Create and start the container
docker run -d \
  --name stash \
  -p 9999:9999 \
  -v /home/mk/docker/stash/config:/root/.stash \
  -v /home/mk/docker/stash/media:/data \
  -v /home/mk/docker/stash/metadata:/metadata \
  -v /home/mk/docker/stash/cache:/cache \
  -v /home/mk/docker/stash/generated:/generated \
  -v /mnt/truenas-media:/mnt/truenas-media:rw \
  -e STASH_STASH="/data" \
  -e STASH_GENERATED="/generated" \
  -e STASH_METADATA="/metadata" \
  -e STASH_CACHE="/cache" \
  -e TZ="America/Chicago" \
  --restart unless-stopped \
  --memory="1g" \
  --label traefik.enable="true" \
  --label traefik.http.routers.stash.rule='Host(`stash.1815.space`)' \
  --label traefik.http.services.stash.loadbalancer.server.port="9999" \
  stashapp/stash:latest

# 4. Verify it's running
docker ps | grep stash
```

## Option 3: Using Docker Compose

Create a file `/home/mk/docker/stash/docker-compose.yml`:

```yaml
version: '3.4'
services:
  stash:
    image: stashapp/stash:latest
    container_name: stash
    restart: unless-stopped
    ports:
      - "9999:9999"
    volumes:
      - /home/mk/docker/stash/config:/root/.stash
      - /home/mk/docker/stash/media:/data
      - /home/mk/docker/stash/metadata:/metadata
      - /home/mk/docker/stash/cache:/cache
      - /home/mk/docker/stash/generated:/generated
      - /mnt/truenas-media:/mnt/truenas-media:rw
    environment:
      - STASH_STASH=/data
      - STASH_GENERATED=/generated
      - STASH_METADATA=/metadata
      - STASH_CACHE=/cache
      - TZ=America/Chicago
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.stash.rule=Host(`stash.1815.space`)"
      - "traefik.http.services.stash.loadbalancer.server.port=9999"
```

Then run:
```bash
cd /home/mk/docker/stash
docker-compose up -d
```

## Verification

After deployment, verify Stash is running:

```bash
# Check container status
docker ps | grep stash

# Check logs
docker logs stash

# Test local access
curl -I http://localhost:9999
```

## Access Stash

- **Local**: http://192.168.12.210:9999
- **External**: https://stash.1815.space (after configuring Cloudflare tunnel)

## Cloudflare Tunnel Configuration

Add this public hostname in your Cloudflare tunnel:
- **Subdomain**: `stash`
- **Domain**: `1815.space`
- **Service**: `http://localhost:80`

## Troubleshooting

If the container doesn't start:
1. Check logs: `docker logs stash`
2. Verify directories exist: `ls -la /home/mk/docker/stash/`
3. Check port availability: `netstat -tulpn | grep 9999`
4. Ensure Traefik is running: `docker ps | grep traefik`