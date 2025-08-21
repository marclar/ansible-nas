#!/bin/bash

echo "======================================"
echo "Reclaim Plex Media Server"
echo "======================================"
echo ""
echo "This will link your Plex server to your Plex account"
echo ""

# Check if we can reach the VM
if ! ssh -o ConnectTimeout=2 mk@192.168.12.100 "echo 'Connected'" &>/dev/null; then
    echo "❌ Cannot connect to VM at 192.168.12.100"
    exit 1
fi

echo "Step 1: Get a claim token"
echo "------------------------"
echo "Go to: https://www.plex.tv/claim"
echo "Copy the claim token (valid for 4 minutes)"
echo ""
read -p "Paste your claim token here: " CLAIM_TOKEN

if [ -z "$CLAIM_TOKEN" ]; then
    echo "❌ No token provided"
    exit 1
fi

echo ""
echo "Step 2: Claiming server..."
echo "------------------------"

# Try to claim the server
ssh mk@192.168.12.100 "docker exec plex curl -X POST 'http://localhost:32400/myplex/claim?token=${CLAIM_TOKEN}' 2>/dev/null"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Server claimed successfully!"
    echo ""
    echo "Step 3: Setting up libraries"
    echo "----------------------------"
    echo "1. Go to https://plex.1815.space"
    echo "2. You should now see your server"
    echo "3. Add libraries:"
    echo "   - Movies: /movies"
    echo "   - TV Shows: /tv"
    echo "   - Photos: /photos"
    echo "   - Music: /music"
else
    echo ""
    echo "❌ Failed to claim server"
    echo "Make sure the token is valid (expires in 4 minutes)"
fi