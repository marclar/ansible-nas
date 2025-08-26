#!/bin/bash

# Tdarr Deployment Script for Ansible-NAS
# Tdarr is a distributed transcoding system for automating media library optimization

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
SERVER_IP="192.168.12.100"
TDARR_PORT="8265"
TDARR_SERVER_PORT="8266"
NFS_MOUNT="/mnt/truenas-media"
DOCKER_DATA="/home/mk/docker"

echo -e "${BLUE}=== Tdarr Deployment for Ansible-NAS ===${NC}"
echo ""

# Function to run commands on server
run_remote() {
    ssh mk@${SERVER_IP} "$1"
}

# Step 1: Create directories
echo -e "${GREEN}1. Creating Tdarr directories...${NC}"
run_remote "mkdir -p ${DOCKER_DATA}/tdarr/config"
run_remote "mkdir -p ${DOCKER_DATA}/tdarr/logs"
run_remote "mkdir -p ${DOCKER_DATA}/tdarr/transcode_cache"
run_remote "mkdir -p ${DOCKER_DATA}/tdarr/server"

# Step 2: Deploy Tdarr Server container
echo -e "${GREEN}2. Deploying Tdarr Server container...${NC}"
run_remote "docker stop tdarr 2>/dev/null || true"
run_remote "docker rm tdarr 2>/dev/null || true"

run_remote "docker run -d \
    --name=tdarr \
    --restart=unless-stopped \
    -e TZ=America/New_York \
    -e PUID=1000 \
    -e PGID=1000 \
    -e UMASK_SET=002 \
    -e serverIP=0.0.0.0 \
    -e serverPort=${TDARR_SERVER_PORT} \
    -e webUIPort=${TDARR_PORT} \
    -e internalNode=true \
    -e inContainer=true \
    -e ffmpegVersion=6 \
    -e nodeName=InternalNode \
    -v ${DOCKER_DATA}/tdarr/server:/app/server \
    -v ${DOCKER_DATA}/tdarr/config:/app/configs \
    -v ${DOCKER_DATA}/tdarr/logs:/app/logs \
    -v ${DOCKER_DATA}/tdarr/transcode_cache:/temp \
    -v ${NFS_MOUNT}/movies:/media/movies \
    -v ${NFS_MOUNT}/tv:/media/tv \
    -p ${TDARR_PORT}:${TDARR_PORT} \
    -p ${TDARR_SERVER_PORT}:${TDARR_SERVER_PORT} \
    --label traefik.enable=true \
    --label traefik.http.routers.tdarr.rule='Host(\`tdarr.1815.space\`)' \
    --label traefik.http.routers.tdarr.entrypoints=web \
    --label traefik.http.services.tdarr.loadbalancer.server.port=${TDARR_PORT} \
    ghcr.io/haveagitgat/tdarr:latest"

echo -e "${GREEN}3. Waiting for Tdarr to start...${NC}"
sleep 10

# Step 4: Check if container is running
echo -e "${GREEN}4. Checking container status...${NC}"
if run_remote "docker ps | grep -q tdarr"; then
    echo -e "${GREEN}✅ Tdarr container is running${NC}"
else
    echo -e "${RED}❌ Tdarr container failed to start${NC}"
    echo -e "${YELLOW}Checking logs...${NC}"
    run_remote "docker logs tdarr --tail 50"
    exit 1
fi

# Step 5: Add to Traefik manual services if needed
echo -e "${GREEN}5. Checking Traefik configuration...${NC}"
if ! run_remote "grep -q 'tdarr' /home/mk/docker/traefik/manual-services.toml 2>/dev/null"; then
    echo -e "${YELLOW}Adding Tdarr to Traefik manual services...${NC}"
    
    run_remote "cat >> /home/mk/docker/traefik/manual-services.toml << 'EOF'

# Tdarr Transcoding System
[http.routers.tdarr]
  rule = \"Host(\\\`tdarr.1815.space\\\`)\"
  entryPoints = [\"web\"]
  service = \"tdarr\"

[http.services.tdarr]
  [http.services.tdarr.loadBalancer]
    [[http.services.tdarr.loadBalancer.servers]]
      url = \"http://192.168.12.100:${TDARR_PORT}\"
EOF"
    
    echo -e "${YELLOW}Restarting Traefik...${NC}"
    run_remote "docker restart traefik"
    sleep 5
fi

# Step 6: Test access
echo -e "${GREEN}6. Testing Tdarr access...${NC}"
echo -e "${BLUE}Local access:${NC} http://${SERVER_IP}:${TDARR_PORT}"
echo -e "${BLUE}External access:${NC} https://tdarr.1815.space"

# Test local access
if curl -s -o /dev/null -w "%{http_code}" "http://${SERVER_IP}:${TDARR_PORT}" | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✅ Local access working${NC}"
else
    echo -e "${YELLOW}⚠️  Local access may need a moment to initialize${NC}"
fi

echo ""
echo -e "${GREEN}=== Tdarr Deployment Complete ===${NC}"
echo ""
echo -e "${BLUE}Access Tdarr at:${NC}"
echo "  - Local: http://${SERVER_IP}:${TDARR_PORT}"
echo "  - External: https://tdarr.1815.space"
echo ""
echo -e "${YELLOW}Initial Setup:${NC}"
echo "1. Access the Tdarr web UI"
echo "2. Configure your libraries (Movies: /media/movies, TV: /media/tv)"
echo "3. Set up transcoding profiles for your needs"
echo "4. Configure plugins for automated processing"
echo ""
echo -e "${BLUE}Default Paths:${NC}"
echo "  Config: ${DOCKER_DATA}/tdarr/config"
echo "  Logs: ${DOCKER_DATA}/tdarr/logs"
echo "  Transcode Cache: ${DOCKER_DATA}/tdarr/transcode_cache"
echo "  Movies: ${NFS_MOUNT}/movies"
echo "  TV Shows: ${NFS_MOUNT}/tv"