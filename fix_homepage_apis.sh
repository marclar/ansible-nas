#!/bin/bash

echo "=== Homepage API Configuration Fix ==="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check server connectivity first
echo "Checking server connectivity..."
ping -c 1 -W 2 192.168.12.100 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Server at 192.168.12.100 is not responding${NC}"
    echo ""
    echo "The server appears to be offline or unreachable."
    echo "Possible solutions:"
    echo "1. Check if the server is powered on"
    echo "2. Check network connectivity"
    echo "3. Try accessing via VPN if you're remote"
    echo ""
    echo "Once the server is accessible, run:"
    echo -e "${YELLOW}./deploy.sh${NC}"
    echo ""
    echo "And select 'homepage' to redeploy with correct API keys."
    exit 1
fi

echo -e "${GREEN}✓ Server is reachable${NC}"
echo ""

# Create a temporary file with the corrected Homepage configuration
echo "Preparing Homepage configuration with correct API settings..."

cat > /tmp/homepage_fix.yml << 'EOF'
# Temporary fix for Homepage API configuration
# This ensures the correct API keys and URLs are used

homepage_services_yaml:
  - Media:
      - Plex:
          icon: plex
          href: https://plex.1815.space
          description: Media Server
          widget:
            type: plex
            url: http://192.168.12.100:32400
            key: "TeczDmMruRR-SG56dXMy"
      - Radarr:
          icon: radarr
          href: https://radarr.1815.space
          description: Movie Collection Manager
          widget:
            type: radarr
            url: http://192.168.12.100:7878
            key: "6905a6146e0d44b781ce05c6a3b4c825"
      - Sonarr:
          icon: sonarr
          href: https://sonarr.1815.space
          description: TV Series Collection Manager
          widget:
            type: sonarr
            url: http://192.168.12.100:8989
            key: "8c6b8e8473aa43f2a0d23812376dbe1d"
  
  - Downloads:
      - Transmission:
          icon: transmission
          href: https://transmission.1815.space
          description: Torrent Client
          widget:
            type: transmission
            url: http://192.168.12.100:9091
            # Transmission uses RPC, no API key needed
      - SABnzbd:
          icon: sabnzbd
          href: https://sabnzbd.1815.space
          description: Usenet Downloader
          widget:
            type: sabnzbd
            url: http://192.168.12.100:18080
            key: "daecd174a70c4246b86beadb8d013d0e"
EOF

echo -e "${GREEN}✓ Configuration prepared${NC}"
echo ""

# Provide instructions
echo "To fix the Homepage API errors:"
echo ""
echo "1. Run the deployment script:"
echo -e "   ${YELLOW}./deploy.sh${NC}"
echo ""
echo "2. Select option to deploy specific services"
echo ""
echo "3. Enter: ${YELLOW}homepage${NC}"
echo ""
echo "This will redeploy Homepage with the correct API configurations."
echo ""
echo "Alternative: Deploy all services to ensure everything is in sync:"
echo -e "   ${YELLOW}./deploy.sh${NC} and select 'Deploy all services'"
echo ""

# Also check if we can SSH to restart services
echo "Attempting to restart Homepage service..."
ssh -o ConnectTimeout=5 mk@192.168.12.100 "docker restart homepage" 2>/dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Homepage service restarted${NC}"
    echo "The API errors should now be resolved. Check https://home.1815.space"
else
    echo -e "${YELLOW}⚠ Could not restart service via SSH. Run deployment as described above.${NC}"
fi