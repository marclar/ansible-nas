# Webhook Security Guidelines

Best practices for securing public webhook endpoints bypassing Cloudflare Access authentication.

## Security Layers

### 1. API Key Authentication
**Implementation:**
- Use strong, randomly generated API keys (minimum 32 characters)
- Store keys in environment variables, never in code
- Validate keys on every request before processing

**Key Generation:**
```bash
# Generate secure API key
openssl rand -hex 32
# Output: 64 character hex string

# Or base64 for more entropy
openssl rand -base64 48
# Output: 64 character base64 string
```

**Rotation Schedule:**
- Rotate keys every 90 days
- Keep previous key active for 24 hours during rotation
- Log key usage to detect compromised keys

### 2. Rate Limiting

**Recommended Limits:**
- Per IP: 30 requests per minute
- Per API key: 100 requests per minute
- Global: 1000 requests per minute

**Implementation Strategies:**
- **In-memory** (simple, resets on restart):
  ```javascript
  const rateLimits = {};
  const limit = 30;
  const window = 60000; // 1 minute
  ```

- **Redis** (persistent, distributed):
  ```javascript
  await redis.incr(`rate:${ip}`);
  await redis.expire(`rate:${ip}`, 60);
  ```

- **Database** (persistent, auditable):
  ```sql
  INSERT INTO rate_limits (ip, timestamp) VALUES (?, NOW());
  SELECT COUNT(*) FROM rate_limits 
  WHERE ip = ? AND timestamp > DATE_SUB(NOW(), INTERVAL 1 MINUTE);
  ```

### 3. Request Validation

**Payload Size Limits:**
- Maximum body size: 100KB for JSON
- Maximum file upload: 10MB
- Maximum URL length: 2048 characters

**Content Type Validation:**
```javascript
const allowedTypes = ['application/json', 'multipart/form-data'];
if (!allowedTypes.includes(contentType)) {
  return error(415, 'Unsupported Media Type');
}
```

**Input Sanitization:**
- Validate JSON schema
- Escape HTML/SQL in text fields
- Validate URLs with regex
- Check file extensions and MIME types

### 4. Monitoring & Logging

**What to Log:**
```json
{
  "timestamp": "2025-08-25T10:30:00Z",
  "ip": "192.168.1.1",
  "userAgent": "iOS/17.0 Shortcuts",
  "apiKeyHash": "sha256:abc123...",
  "endpoint": "/webhook/linky",
  "method": "POST",
  "status": 200,
  "responseTime": 145,
  "payloadSize": 2048
}
```

**Alert Triggers:**
- Rate limit exceeded by same IP (possible attack)
- Invalid API key attempts > 10 per hour
- Payload size violations
- Error rate > 5% in 5 minutes
- Response time > 1 second

### 5. Network Security

**IP Allowlisting (Optional):**
```javascript
const allowedIPs = process.env.ALLOWED_IPS?.split(',') || [];
if (allowedIPs.length > 0 && !allowedIPs.includes(sourceIP)) {
  return error(403, 'IP not allowed');
}
```

**Cloudflare IP Verification:**
```javascript
// Verify request comes through Cloudflare
const cfIPs = ['173.245.48.0/20', '103.21.244.0/22', ...];
if (!isIPInRange(sourceIP, cfIPs)) {
  return error(403, 'Direct access not allowed');
}
```

### 6. Response Security

**Headers to Include:**
```javascript
response.headers = {
  'X-Content-Type-Options': 'nosniff',
  'X-Frame-Options': 'DENY',
  'X-XSS-Protection': '1; mode=block',
  'Content-Security-Policy': "default-src 'none'",
  'Strict-Transport-Security': 'max-age=31536000',
  'X-Request-Id': generateRequestId()
};
```

**Error Responses:**
- Don't leak internal information
- Use generic error messages
- Include request ID for debugging
- Return appropriate HTTP status codes

### 7. Backup Security Measures

**Circuit Breaker Pattern:**
```javascript
let failureCount = 0;
const threshold = 10;
const timeout = 60000;

if (failureCount > threshold) {
  // Circuit open - reject all requests
  return error(503, 'Service temporarily unavailable');
}
```

**Honeypot Endpoints:**
```javascript
// Create fake endpoints to detect scanners
app.post('/admin', (req, res) => {
  logSuspiciousActivity(req.ip);
  blacklistIP(req.ip);
  return error(404);
});
```

## Implementation Checklist

### Initial Setup
- [ ] Generate strong API key
- [ ] Configure Cloudflare Access bypass
- [ ] Implement API key validation
- [ ] Add basic rate limiting
- [ ] Set up error handling
- [ ] Configure logging

### Security Hardening
- [ ] Add request size limits
- [ ] Implement input validation
- [ ] Add response security headers
- [ ] Set up monitoring alerts
- [ ] Configure backup rate limits
- [ ] Test error scenarios

### Maintenance
- [ ] Schedule key rotation
- [ ] Review logs weekly
- [ ] Update rate limits based on usage
- [ ] Monitor for suspicious patterns
- [ ] Test webhook regularly
- [ ] Update documentation

## Testing Security

### Manual Testing
```bash
# Test valid request
curl -X POST https://n8n.1815.space/webhook/linky \
  -H "X-API-Key: your-key" \
  -H "Content-Type: application/json" \
  -d '{"type":"url","url":"https://example.com"}'

# Test missing API key
curl -X POST https://n8n.1815.space/webhook/linky \
  -H "Content-Type: application/json" \
  -d '{"type":"url"}'

# Test invalid API key
curl -X POST https://n8n.1815.space/webhook/linky \
  -H "X-API-Key: wrong-key" \
  -d '{"type":"url"}'

# Test rate limiting
for i in {1..50}; do
  curl -X POST https://n8n.1815.space/webhook/linky \
    -H "X-API-Key: your-key" \
    -d '{"test":"'$i'"}'
done

# Test large payload
curl -X POST https://n8n.1815.space/webhook/linky \
  -H "X-API-Key: your-key" \
  -d @large-file.json
```

### Automated Security Scanning
```bash
# Use OWASP ZAP
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://n8n.1815.space/webhook/linky

# Use Nikto
nikto -h https://n8n.1815.space/webhook/linky

# Use SQLMap (for SQL injection)
sqlmap -u "https://n8n.1815.space/webhook/linky" \
  --data='{"test":"value"}' \
  --headers="X-API-Key: your-key"
```

## Incident Response

### If API Key is Compromised
1. Generate new API key immediately
2. Update n8n environment variable
3. Update iOS Shortcuts
4. Review logs for unauthorized access
5. Check for data exfiltration
6. Document incident

### If Under Attack
1. Enable stricter rate limiting
2. Block attacking IPs at Cloudflare
3. Temporarily disable bypass (require auth)
4. Analyze attack patterns
5. Implement additional filters
6. Report to authorities if necessary

### Recovery Procedures
1. Verify all security measures active
2. Test legitimate access
3. Review and update security rules
4. Document lessons learned
5. Update runbooks

## Monitoring Commands

```bash
# Check recent webhook calls
ssh mk@192.168.12.100 "docker logs n8n --tail 100 | grep webhook"

# Monitor real-time activity
ssh mk@192.168.12.100 "docker logs -f n8n | grep linky"

# Check rate limit hits
ssh mk@192.168.12.100 "docker logs n8n | grep 'Rate limit'"

# Export logs for analysis
ssh mk@192.168.12.100 "docker logs n8n" > webhook-logs.txt
grep "X-API-Key" webhook-logs.txt | wc -l
```

## Regular Audits

### Weekly
- Review webhook logs
- Check for unusual patterns
- Verify rate limits working
- Test with iOS Shortcut

### Monthly
- Analyze usage statistics
- Review security alerts
- Update rate limits if needed
- Test all error conditions

### Quarterly
- Rotate API keys
- Security assessment
- Update documentation
- Review and update rules

---

Last Updated: 2025-08-25
Security Level: Medium (API Key + Rate Limiting)
Suitable for: Personal use, low-sensitivity data