# Browserless - Chrome as a Service

Browserless is a web service that allows for remote clients to connect, drive, and execute headless work, all inside of Docker. It's designed to be a drop-in replacement for headless Chrome that's easy to host yourself.

## Features

- Remote Chrome browser automation
- Compatible with Puppeteer and Playwright
- WebSocket and REST API interfaces
- Built-in debugging tools
- Session management and queueing
- Screenshot and PDF generation
- Web scraping capabilities

## Configuration

Enable Browserless in your `inventories/<your_inventory>/group_vars/nas.yml`:

```yaml
browserless_enabled: true
browserless_port: 3000
browserless_concurrent: 10
browserless_token: "your-secure-token-here"
browserless_available_externally: false
```

## Usage

### Connecting with Puppeteer

```javascript
const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.connect({
    browserWSEndpoint: 'ws://localhost:3000?token=your-secure-token-here'
  });
  
  const page = await browser.newPage();
  await page.goto('https://example.com');
  await page.screenshot({ path: 'example.png' });
  await browser.close();
})();
```

### Connecting with Playwright

```javascript
const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.connect({
    wsEndpoint: 'ws://localhost:3000?token=your-secure-token-here'
  });
  
  const context = await browser.newContext();
  const page = await context.newPage();
  await page.goto('https://example.com');
  await page.screenshot({ path: 'example.png' });
  await browser.close();
})();
```

### Using with n8n

In n8n, you can use Browserless with the Puppeteer or Playwright nodes by:

1. Setting the WebSocket endpoint to: `ws://browserless:3000?token=your-token`
2. Using the browserless container name if both are in the same Docker network

### REST API Examples

#### Generate Screenshot
```bash
curl -X POST \
  http://localhost:3000/screenshot?token=your-token \
  -H 'Content-Type: application/json' \
  -d '{
    "url": "https://example.com",
    "options": {
      "fullPage": true,
      "type": "png"
    }
  }' \
  --output screenshot.png
```

#### Generate PDF
```bash
curl -X POST \
  http://localhost:3000/pdf?token=your-token \
  -H 'Content-Type: application/json' \
  -d '{
    "url": "https://example.com",
    "options": {
      "format": "A4",
      "printBackground": true
    }
  }' \
  --output document.pdf
```

## Security

- Always use a strong, unique token
- Consider enabling external access only with proper authentication
- Monitor concurrent connections to prevent abuse
- Use Traefik labels for additional security layers

## Environment Variables

- `CONCURRENT`: Maximum number of concurrent Chrome instances
- `TOKEN`: Authentication token (required)
- `MAX_QUEUE_LENGTH`: Maximum number of queued requests
- `TIMEOUT`: Default timeout for browser operations (ms)
- `WORKSPACE_DIR`: Temporary workspace directory
- `DOWNLOAD_DIR`: Directory for downloaded files
- `ENABLE_CORS`: Enable CORS headers
- `DEFAULT_BLOCK_ADS`: Block ads by default
- `DEFAULT_STEALTH`: Use stealth mode by default

## Debugging

Access the built-in debugger at: `http://localhost:3000/docs`

## Resources

- [Official Documentation](https://docs.browserless.io)
- [GitHub Repository](https://github.com/browserless/chrome)
- [API Documentation](https://docs.browserless.io/docs/apis)