FROM docker.n8n.io/n8nio/n8n:latest

USER root

# Install Chromium and essential dependencies for both Puppeteer and Playwright
RUN apk add --no-cache \
    chromium \
    chromium-chromedriver \
    nss \
    freetype \
    freetype-dev \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    nodejs \
    yarn \
    # Core X11 dependencies
    libx11 \
    libxcomposite \
    libxdamage \
    libxext \
    libxfixes \
    libxrandr \
    libxrender \
    libxtst \
    libxshmfence \
    # Graphics libraries
    mesa-gl \
    mesa-gles \
    mesa-gbm \
    # Audio/Video libraries
    alsa-lib \
    # Core system libraries
    at-spi2-core \
    cups-libs \
    dbus-libs \
    expat \
    gdk-pixbuf \
    glib \
    gtk+3.0 \
    libdrm \
    libjpeg-turbo \
    libpng \
    libwebp \
    libx11-dev \
    libxcb \
    libxkbcommon \
    libxscrnsaver \
    pango \
    wayland \
    # XCB utilities
    xcb-util \
    xcb-util-image \
    xcb-util-keysyms \
    xcb-util-renderutil \
    xcb-util-wm \
    zlib

# Tell Puppeteer and Playwright to use system Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    CHROME_BIN=/usr/bin/chromium-browser \
    CHROME_PATH=/usr/lib/chromium/ \
    PUPPETEER_ARGS="--no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage --disable-gpu" \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=1 \
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium-browser \
    PLAYWRIGHT_BROWSERS_PATH=/usr/bin

# Install glibc compatibility for bundled browsers (as fallback)
RUN apk add --no-cache gcompat

# Set up Chrome sandbox permissions and Playwright cache
RUN mkdir -p /home/node/.cache/puppeteer && \
    mkdir -p /home/node/.cache/ms-playwright && \
    mkdir -p /home/node/.local/share && \
    chmod -R 777 /home/node/.cache && \
    chmod -R 777 /home/node/.local

# Create wrapper script for Chrome that will be copied to various locations
RUN echo '#!/bin/sh' > /tmp/chrome-wrapper && \
    echo 'exec /usr/bin/chromium-browser --no-sandbox --disable-setuid-sandbox --disable-dev-shm-usage --disable-gpu --no-zygote --single-process "$@"' >> /tmp/chrome-wrapper && \
    chmod +x /tmp/chrome-wrapper

# Set up Playwright browser paths for multiple versions
RUN for version in 1134 1140 1148 1179 1187 1190; do \
      mkdir -p /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/chrome-linux && \
      cp /tmp/chrome-wrapper /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/chrome-linux/chrome && \
      echo "{\"name\":\"chromium\",\"revision\":\"${version}\"}" > /home/node/.n8n/nodes/node_modules/n8n-nodes-playwright/dist/nodes/browsers/chromium-${version}/browser.json && \
      mkdir -p /home/node/.cache/ms-playwright/chromium-${version} && \
      cp /tmp/chrome-wrapper /home/node/.cache/ms-playwright/chromium-${version}/chrome; \
    done

# Set ownership for all n8n directories
RUN chown -R node:node /home/node

# Copy and set up custom entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER node

ENTRYPOINT ["/entrypoint.sh"]