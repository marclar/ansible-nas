#!/bin/bash

# Fix VM network connectivity

echo "Fixing VM network..."
echo "===================="
echo ""

# Find the main network interface (not docker0 or lo)
INTERFACE=$(ip link