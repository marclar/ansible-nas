#!/bin/bash

# Manual Stash deployment script
echo "Manual Stash deployment..."

# SSH to server and create directories
ssh mk@192.168.12.210 << 'EOF'
echo "Creating Stash directories..."
mkdir -p /home/mk/docker/stash/{config,media,metadata,cache,generated}

echo "Starting Stash container..."
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

echo "Checking container status..."
docker ps | grep stash
EOF

echo "Stash deployment complete!"
echo "Access at: http://192.168.12.210:9999 or https://stash.1815.space"