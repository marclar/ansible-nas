# Cloudflare Access Bypass for n8n Webhook

This guide explains how to configure a public webhook endpoint that bypasses Cloudflare Access authentication while keeping your other services protected.

## Overview

We'll create a specific path (`/webhook/linky`) on your n8n service that can be accessed publicly without Cloudflare authentication, secured only by an API key in the HTTP headers.

## Step 1: Configure Cloudflare Access Bypass

### In Cloudflare Zero Trust Dashboard:

1. **Log in to Cloudflare Zero Trust**
   - Go to https://one.dash.cloudflare.com/
   - Select your account

2. **Navigate to Access > Applications**

3. **Create a New Application for the Webhook Path**
   - Click "Add an application"
   - Select "Self-hosted"
   - Configure as follows:

   **Application Configuration:**
   ```
   Application name: n8n Webhook Bypass
   Session Duration: No session (API/webhook)
   Application domain: n8n.1815.space
   Path: /webhook/linky
   ```

4. **Configure the Bypass Policy**
   - Click "Next" to go to Policies
   - Add a new policy:
   ```
   Policy name: Public Webhook Access
   Action: Bypass
   Session duration: No session
   
   Include:
   Selector: Everyone
   Value: Everyone
   ```
   - Click "Next" then "Add application"

5. **IMPORTANT: Reorder Applications**
   - In the Applications list, find your new "n8n Webhook Bypass" application
   - Drag it ABOVE the main "n8n" application
   - The order must be:
     1. n8n Webhook Bypass (path: /webhook/linky) - Bypass policy
     2. n8n (main application) - Regular authentication

## Step 2: Configure n8n Webhook with Security

### Create a Secure Webhook in n8n:

1. **Access n8n** at https://n8n.1815.space (with authentication)

2. **Create New Workflow** named "Linky - Public Webhook"

3. **Add Webhook Node:**
   ```
   HTTP Method: POST
   Path: linky
   Authentication: None (we'll validate manually)
   Response Mode: Last Node
   ```

4. **Add Code Node for API Key Validation:**
   ```javascript
   // API Key Validation Node
   const headers = $input.first().headers;
   const apiKey = headers['x-api-key'] || headers['X-API-Key'];
   
   // Store your API key in n8n environment variables
   const validKey = $env.LINKY_API_KEY || 'your-super-secret-api-key-here';
   
   if (!apiKey || apiKey !== validKey) {
     throw new Error('Invalid or missing API key');
   }
   
   // Add metadata
   const data = $input.first().json;
   data.authenticated = true;
   data.receivedAt = new Date().toISOString();
   data.sourceIP = headers['cf-connecting-ip'] || headers['x-forwarded-for'];
   
   return [data];
   ```

5. **Save and Activate the Workflow**

6. **Note the Webhook URL:**
   ```
   https://n8n.1815.space/webhook/linky
   ```

## Step 3: Set n8n Environment Variable

### Add API Key to n8n:

SSH to your server and add the environment variable:

```bash
# Add to n8n container environment
ssh mk@192.168.12.100
docker stop n8n
docker rm n8n

# Recreate with API key environment variable
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e N8N_BASIC_AUTH_ACTIVE=true \
  -e N8N_BASIC_AUTH_USER=admin \
  -e N8N_BASIC_AUTH_PASSWORD=your-password \
  -e LINKY_API_KEY=your-super-secret-api-key-here \
  -v /opt/n8n:/home/node/.n8n \
  n8nio/n8n
```

## Step 4: Test the Bypass

### Test Public Access:

```bash
# This should work WITHOUT authentication
curl -X POST https://n8n.1815.space/webhook/linky \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-super-secret-api-key-here" \
  -d '{"test": "data"}'

# This should return 401 (wrong API key)
curl -X POST https://n8n.1815.space/webhook/linky \
  -H "Content-Type: application/json" \
  -H "X-API-Key: wrong-key" \
  -d '{"test": "data"}'

# This should require Cloudflare authentication
curl https://n8n.1815.space/
```

## Step 5: iOS Shortcut Configuration

Update your iOS Shortcut to use the public endpoint:

```
URL: https://n8n.1815.space/webhook/linky
Method: POST
Headers:
  Content-Type: application/json
  X-API-Key: your-super-secret-api-key-here
Body: {
  "type": "url",
  "url": "[Shortcut Input]",
  "source": "ios"
}
```

## Security Recommendations

### 1. Use a Strong API Key
Generate a secure key:
```bash
openssl rand -hex 32
```

### 2. Add Rate Limiting in n8n
Add a Function node after validation:
```javascript
// Rate limiting (simple in-memory example)
const ip = $input.first().json.sourceIP;
const now = Date.now();
const limit = 10; // requests per minute
const window = 60000; // 1 minute

// This is simplified - use Redis for production
const requests = $getWorkflowStaticData('requests') || {};
const ipRequests = requests[ip] || [];

// Clean old requests
const recentRequests = ipRequests.filter(time => now - time < window);

if (recentRequests.length >= limit) {
  throw new Error('Rate limit exceeded');
}

recentRequests.push(now);
requests[ip] = recentRequests;
$setWorkflowStaticData('requests', requests);

return [$input.first().json];
```

### 3. Add Request Size Limits
Check payload size in validation:
```javascript
const payload = JSON.stringify($input.first().json);
if (payload.length > 10000) { // 10KB limit
  throw new Error('Payload too large');
}
```

### 4. Log All Requests
Add a logging node to track usage:
```javascript
// Log to n8n execution history
console.log('Webhook received:', {
  ip: $input.first().json.sourceIP,
  timestamp: new Date().toISOString(),
  type: $input.first().json.type
});
```

### 5. Monitor for Abuse
- Check n8n execution logs regularly
- Set up alerts for high request volumes
- Rotate API key periodically

## Troubleshooting

### Webhook returns 404
- Check that the webhook path in n8n matches `/webhook/linky`
- Ensure the workflow is active

### Still requires authentication
- Verify the bypass application is ABOVE the main application in Cloudflare
- Check that the path exactly matches `/webhook/linky`
- Clear browser cache and cookies

### API key not working
- Check header name matches (X-API-Key)
- Verify environment variable is set in n8n container
- Check for typos in the key

## Alternative: Traefik Path-Based Bypass

If you prefer not to use Cloudflare's bypass feature, you can configure Traefik to expose a specific path publicly:

```toml
# In /home/mk/docker/traefik/manual-services.toml
[http.routers.n8n-webhook]
  rule = "Host(`webhook.1815.space`) && PathPrefix(`/linky`)"
  entryPoints = ["web"]
  service = "n8n-webhook"
  middlewares = ["api-auth"]

[http.middlewares.api-auth.headers]
  customRequestHeaders.X-API-Required = "true"

[http.services.n8n-webhook]
  [http.services.n8n-webhook.loadBalancer]
    [[http.services.n8n-webhook.loadBalancer.servers]]
      url = "http://192.168.12.100:5678"
```

Then create a CNAME for `webhook.1815.space` pointing directly to your public IP (bypassing Cloudflare Tunnel).

---

Last Updated: 2025-08-25