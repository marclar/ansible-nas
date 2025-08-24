#!/bin/bash

# Build Grimoire for ARM64 architecture
# This script builds Grimoire from source for ARM64 systems

set -e

echo "=== Building Grimoire for ARM64 ==="
echo ""

# Configuration
REPO_URL="https://github.com/goniszewski/grimoire.git"
BUILD_DIR="/tmp/grimoire-build"
IMAGE_NAME="grimoire-arm64"
IMAGE_TAG="latest"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}This will build Grimoire from source for ARM64 architecture${NC}"
echo "This process may take 10-15 minutes..."
echo ""

read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled"
    exit 1
fi

# Clone repository
echo -e "${GREEN}Cloning Grimoire repository...${NC}"
rm -rf $BUILD_DIR
git clone $REPO_URL $BUILD_DIR
cd $BUILD_DIR

# Build for ARM64
echo -e "${GREEN}Building Docker image for ARM64...${NC}"
docker buildx build \
    --platform linux/arm64 \
    -t $IMAGE_NAME:$IMAGE_TAG \
    --load \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    echo ""
    echo "To use this image, update your Ansible configuration:"
    echo "  grimoire_image_name: \"$IMAGE_NAME\""
    echo "  grimoire_image_version: \"$IMAGE_TAG\""
    echo ""
    echo "Then redeploy:"
    echo "  ansible-playbook -i inventories/production/inventory nas.yml --tags grimoire"
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi

# Cleanup
cd /
rm -rf $BUILD_DIR

echo -e "${GREEN}Build complete!${NC}"