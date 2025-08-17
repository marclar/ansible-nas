#!/bin/bash
# Plex library scanner script
export LD_LIBRARY_PATH=/usr/lib/plexmediaserver/lib
export PLEX_MEDIA_SERVER_HOME=/usr/lib/plexmediaserver
export PLEX_MEDIA_SERVER_APPLICATION_SUPPORT_DIR=/config/Library/Application\ Support

# Scan all libraries
/usr/lib/plexmediaserver/Plex\ Media\ Scanner --scan --refresh