#!/bin/bash

# Plex Orphaned Server Cleanup Script
# This script identifies and reports orphaned Plex servers

PLEX_TOKEN="wyKrx5etYE618yw_HSXZ"
ACTIVE_SERVER_ID="a7b7c93725ee2f50c399a58ccbdd91294431adf3"
ACTIVE_SERVER_NAME="ansible-nas"

echo "========================================="
echo "Plex Server Status Check"
echo "========================================="
echo ""

# Get all Plex servers from the account
echo "Fetching registered Plex servers..."
SERVERS=$(curl -s -H "X-Plex-Token: $PLEX_TOKEN" 'https://plex.tv/api/resources' | grep 'Device name=' | grep 'Plex Media Server')

# Count total servers
TOTAL_SERVERS=$(echo "$SERVERS" | grep -c 'Plex Media Server')
echo "Total Plex servers found: $TOTAL_SERVERS"
echo ""

# Parse and display server details
echo "Server Details:"
echo "---------------"
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        NAME=$(echo "$line" | sed 's/.*name="\([^"]*\)".*/\1/')
        ID=$(echo "$line" | sed 's/.*clientIdentifier="\([^"]*\)".*/\1/')
        PRESENCE=$(echo "$line" | sed 's/.*presence="\([^"]*\)".*/\1/')
        LAST_SEEN=$(echo "$line" | sed 's/.*lastSeenAt="\([^"]*\)".*/\1/')
        
        # Convert timestamp to readable date
        if command -v date >/dev/null 2>&1; then
            LAST_SEEN_DATE=$(date -d "@$LAST_SEEN" 2>/dev/null || date -r "$LAST_SEEN" 2>/dev/null || echo "Unknown")
        else
            LAST_SEEN_DATE="Timestamp: $LAST_SEEN"
        fi
        
        STATUS="Inactive"
        if [[ "$PRESENCE" == "1" ]]; then
            STATUS="Active"
        fi
        
        echo "• Server: $NAME"
        echo "  ID: $ID"
        echo "  Status: $STATUS"
        echo "  Last Seen: $LAST_SEEN_DATE"
        
        if [[ "$ID" == "$ACTIVE_SERVER_ID" ]]; then
            echo "  ✓ This is the current production server"
        else
            echo "  ⚠ ORPHANED SERVER - No longer in use"
        fi
        echo ""
    fi
done <<< "$SERVERS"

echo "========================================="
echo "Summary:"
echo "========================================="

# Check for orphaned servers
ORPHANED_COUNT=$((TOTAL_SERVERS - 1))
if [[ $ORPHANED_COUNT -gt 0 ]]; then
    echo "⚠ Found $ORPHANED_COUNT orphaned server(s)"
    echo ""
    echo "Note: Orphaned servers with presence=0 are inactive and"
    echo "typically don't cause issues. They may be automatically"
    echo "removed by Plex after 30 days of inactivity."
    echo ""
    echo "To manually remove orphaned servers:"
    echo "1. Log into https://app.plex.tv"
    echo "2. Go to Settings > Authorized Devices"
    echo "3. Remove old/duplicate servers named '1815'"
else
    echo "✓ No orphaned servers found"
    echo "✓ Only the active production server is registered"
fi

echo ""
echo "Current active server: $ACTIVE_SERVER_NAME (ID: $ACTIVE_SERVER_ID)"