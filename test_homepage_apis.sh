#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Testing Homepage API Connections..."
echo "===================================="
echo ""

# Test Plex
echo -n "Testing Plex API... "
PLEX_KEY="TeczDmMruRR-SG56dXMy"
PLEX_RESPONSE=$(curl -s -w "\n%{http_code}" "http://192.168.12.100:32400/identity?X-Plex-Token=$PLEX_KEY" 2>/dev/null | tail -1)
if [ "$PLEX_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $PLEX_RESPONSE)${NC}"
    # Try without token
    echo -n "  Trying without auth... "
    PLEX_BASIC=$(curl -s -w "\n%{http_code}" "http://192.168.12.100:32400/identity" 2>/dev/null | tail -1)
    if [ "$PLEX_BASIC" = "200" ] || [ "$PLEX_BASIC" = "401" ]; then
        echo -e "${YELLOW}Server responds (HTTP $PLEX_BASIC)${NC}"
    else
        echo -e "${RED}No response${NC}"
    fi
fi

# Test SABnzbd
echo -n "Testing SABnzbd API... "
SAB_KEY="daecd174a70c4246b86beadb8d013d0e"
SAB_RESPONSE=$(curl -s -w "\n%{http_code}" "http://192.168.12.100:18080/api?mode=version&apikey=$SAB_KEY" 2>/dev/null | tail -1)
if [ "$SAB_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $SAB_RESPONSE)${NC}"
    # Check if port is open
    echo -n "  Checking port 18080... "
    nc -z -w 2 192.168.12.100 18080 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}Port is open${NC}"
    else
        echo -e "${RED}Port is closed${NC}"
    fi
fi

# Test Transmission
echo -n "Testing Transmission RPC... "
TRANS_RESPONSE=$(curl -s -w "\n%{http_code}" "http://192.168.12.100:9091/transmission/rpc" 2>/dev/null | tail -1)
if [ "$TRANS_RESPONSE" = "409" ]; then
    # 409 is expected for Transmission RPC without session ID
    echo -e "${GREEN}✓ Server responds correctly${NC}"
elif [ "$TRANS_RESPONSE" = "401" ]; then
    echo -e "${YELLOW}⚠ Requires authentication${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $TRANS_RESPONSE)${NC}"
    # Check if port is open
    echo -n "  Checking port 9091... "
    nc -z -w 2 192.168.12.100 9091 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "${YELLOW}Port is open${NC}"
    else
        echo -e "${RED}Port is closed${NC}"
    fi
fi

# Test Radarr
echo -n "Testing Radarr API... "
RADARR_KEY="b7195ebe0ed54833815c4b38d7f13cda"
RADARR_RESPONSE=$(curl -s -w "\n%{http_code}" "http://192.168.12.100:7878/api/v3/system/status?apikey=$RADARR_KEY" 2>/dev/null | tail -1)
if [ "$RADARR_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $RADARR_RESPONSE)${NC}"
fi

# Test Sonarr
echo -n "Testing Sonarr API... "
SONARR_KEY="1bfe4d8b21284f4f93b1e3cb6f16a302"
SONARR_RESPONSE=$(curl -s -w "\n%{http_code}" "http://192.168.12.100:8989/api/v3/system/status?apikey=$SONARR_KEY" 2>/dev/null | tail -1)
if [ "$SONARR_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Connected${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $SONARR_RESPONSE)${NC}"
fi

echo ""
echo "Testing network connectivity..."
echo -n "Ping to server (192.168.12.100)... "
ping -c 1 -W 2 192.168.12.100 > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Reachable${NC}"
else
    echo -e "${RED}✗ Unreachable${NC}"
fi

echo ""
echo "Note: If services are unreachable, the server may be down or services may need to be restarted."