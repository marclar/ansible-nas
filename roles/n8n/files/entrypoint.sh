#!/bin/sh

# Ensure browser wrapper scripts are in place (in case volume mounts override them)
# This maintains the setup even if /home/node/.n8n is mounted as a volume
if [ ! -f /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-1187/chrome-linux/chrome ]; then
  echo "Setting up Playwright browser paths..."
  
  # Create wrapper script
  cat > /tmp/chrome-wrapper << 'EOF'
#!/bin/sh
exec /usr/bin/chromium-browser \
  --no-sandbox \
  --disable-setuid-sandbox \
  --disable-dev-shm-usage \
  --disable-gpu \
  --no-zygote \
  --single-process \
  "$@"
EOF
  chmod +x /tmp/chrome-wrapper
  
  # Set up for multiple Playwright versions
  for version in 1134 1140 1148 1179 1187 1190; do
    mkdir -p /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/chrome-linux
    cp /tmp/chrome-wrapper /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/chrome-linux/chrome
    
    cat > /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/browser.json << EOF
{
  "name": "chromium",
  "revision": "${version}"
}
EOF
  done
  
  echo "Playwright browser paths configured."
fi

# Start n8n
exec n8n