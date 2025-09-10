#!/bin/sh

echo "Starting n8n with Playwright browser setup..."

# Wait for n8n directory to be ready
sleep 2

# Function to setup browser paths
setup_browser_paths() {
  echo "Configuring Playwright browser paths..."
  
  # Create base directories
  mkdir -p /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers
  
  # Set up for multiple Playwright versions
  for version in 1134 1140 1148 1179 1187 1190; do
    echo "Setting up chromium-${version}..."
    
    # Create the chrome-linux directory
    mkdir -p /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/chrome-linux
    
    # Create a wrapper script that works with Alpine's Chromium
    cat > /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/chrome-linux/chrome << 'WRAPPER'
#!/bin/sh
# Playwright Chrome wrapper for Alpine Linux
exec /usr/bin/chromium-browser \
  --no-sandbox \
  --disable-setuid-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --no-zygote \
  --disable-software-rasterizer \
  --disable-dev-tools \
  "$@"
WRAPPER
    
    chmod +x /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/chrome-linux/chrome
    
    # Create browser.json to indicate the browser is installed
    cat > /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/browser.json << JSON
{
  "name": "chromium",
  "revision": "${version}",
  "installType": "system"
}
JSON
    
    # Also create INSTALLATION_COMPLETE marker
    touch /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/INSTALLATION_COMPLETE
  done
  
  echo "Browser paths configured successfully."
}

# Run setup in background to ensure it's applied after n8n starts
(
  sleep 5
  setup_browser_paths
) &

# Also set up immediately if possible
setup_browser_paths

# Start n8n
exec n8n