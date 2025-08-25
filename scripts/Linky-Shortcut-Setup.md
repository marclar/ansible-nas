# Linky - iOS Shortcut for n8n Integration (Public Endpoint Version)

This shortcut allows you to share URLs and files from any iOS app to your n8n automation service using a public webhook endpoint (no Cloudflare authentication required).

## Prerequisites

1. Configure Cloudflare Access bypass for `/webhook/linky` path (see `cloudflare-webhook-bypass-setup.md`)
2. Import and activate the secure webhook workflow in n8n (see `n8n-secure-webhook-workflow.json`)
3. Set your API key in n8n environment variables

## Setup Instructions

### Step 1: Create the Shortcut

1. Open the Shortcuts app on your iPhone
2. Tap the "+" to create a new shortcut
3. Build the shortcut with the following actions:

### Shortcut Configuration

```
Name: Linky
Accepts: URLs, Files, Text
Shows in Share Sheet: Yes
```

### Actions to Add (in order):

1. **Text Action** - Define Variables
   ```
   n8n Endpoint URL: https://n8n.1815.space/webhook/linky
   API Key: [your-secure-api-key-here]
   Default Tag: inbox
   Note: This endpoint is publicly accessible (no Cloudflare auth)
   ```

2. **Get Variable** - Get Shortcut Input
   - Variable Name: Shortcut Input

3. **If Statement** - Check Input Type
   - If: Shortcut Input has any value

4. **Get Type** - Inside If block
   - Get Type of: Shortcut Input
   - Set to Variable: InputType

5. **If Statement** - Check if URL
   - If: InputType is URL

   **Inside URL Block:**
   6. **Get Contents of URL** - Extract Page Info
      - URL: Shortcut Input
      - Get: Contents of Web Page

   7. **Get Details of Web Page**
      - Get: Name, Page URL
      - From: Contents of URL

   8. **Text Action** - Build JSON for URL
      ```json
      {
        "type": "url",
        "url": "[Page URL]",
        "title": "[Name]",
        "tag": "[Default Tag]",
        "source": "ios-shortcut",
        "timestamp": "[Current Date]"
      }
      ```

   **Otherwise (File/Text Block):**
   9. **Get Details of Files** 
      - Get: Name, File Extension, File Size
      - From: Shortcut Input

   10. **Text Action** - Build JSON for File
       ```json
       {
         "type": "file",
         "filename": "[Name]",
         "extension": "[File Extension]",
         "size": "[File Size]",
         "tag": "[Default Tag]",
         "source": "ios-shortcut",
         "timestamp": "[Current Date]"
       }
       ```

11. **Get Contents of URL** - Send to n8n
    - URL: [n8n Endpoint URL from variables]
    - Method: POST
    - Headers:
      ```
      Content-Type: application/json
      X-API-Key: [API Key from variables]
      ```
    - Request Body: JSON (from step 8 or 10)

12. **If Statement** - Check Response
    - If: Contains "success"
    
    **Inside Success Block:**
    13. **Show Notification**
        - Title: "Linky"
        - Body: "Saved to n8n!"
        - Sound: Success
    
    **Otherwise (Error Block):**
    14. **Show Alert**
        - Title: "Linky Error"
        - Message: "Failed to save. Check your connection."

### Step 2: n8n Webhook Configuration

Create a new workflow in n8n with these nodes:

1. **Webhook Node**
   - HTTP Method: POST
   - Path: linky
   - Authentication: Header Auth
   - Header Name: X-API-Key
   - Header Value: [your-api-key]
   - Response Mode: Immediately
   - Response Data: {"status": "success", "message": "Item received"}

2. **Switch Node** - Route by Type
   - Mode: Rules
   - Rule 1: type equals "url" → URL Processing
   - Rule 2: type equals "file" → File Processing
   - Rule 3: type equals "text" → Text Processing

3. **URL Processing Branch:**
   - **HTTP Request Node** - Fetch Open Graph data
   - **LinkAce Node** (or custom HTTP to LinkAce API)
     - Create new bookmark
     - URL: {{$json["url"]}}
     - Title: {{$json["title"]}}
     - Tags: {{$json["tag"]}}

4. **File Processing Branch:**
   - **Write Binary File Node** - Save to storage
   - **Database Node** - Log file metadata

5. **Text Processing Branch:**
   - **Create Note Node** - Save as note/snippet

6. **Notification Node** (optional)
   - Send success notification to preferred service

### Step 3: Enable Share Sheet

1. In Shortcuts app, tap the shortcut settings (three dots)
2. Toggle "Show in Share Sheet" ON
3. Under "Share Sheet Types" select:
   - URLs
   - Files  
   - Text

### Step 4: Test the Shortcut

1. Open Safari and navigate to any webpage
2. Tap the Share button
3. Select "Linky" from the share sheet
4. Check n8n for the received webhook

## Advanced Features

### Add Quick Tags
Add a **Choose from Menu** action after getting input:
- Personal
- Work  
- Reference
- Read Later
- Archive

### Add Description
Add a **Ask for Text** action:
- Prompt: "Add description (optional)"
- Default Answer: (leave empty)
- Include in JSON payload

### Multiple Endpoints
Use **Choose from Menu** to select different n8n workflows:
- Save to LinkAce
- Create Task
- Add to Reading List
- Archive Document

## Troubleshooting

### Common Issues

1. **"Failed to save" error**
   - Check n8n webhook URL is accessible
   - Verify API key matches
   - Ensure n8n workflow is active

2. **Shortcut not appearing in Share Sheet**
   - Go to Share Sheet → More → Edit Actions
   - Find Linky and add to favorites

3. **URL details not extracted**
   - Some sites block automation
   - Fallback to just sending URL without metadata

### Debug Mode
Add these actions for debugging:
- **Quick Look** action after JSON creation
- **Copy to Clipboard** action for JSON
- **Show Result** action for webhook response

## Security Notes

- Store API key in shortcut as text action (not visible to users)
- Use HTTPS for n8n endpoint
- Consider adding timestamp validation in n8n
- Rotate API keys periodically

## Example n8n Webhook Response

Success:
```json
{
  "status": "success",
  "message": "Item saved",
  "id": "12345",
  "type": "url"
}
```

Error:
```json
{
  "status": "error",
  "message": "Invalid API key"
}
```

## Download Link

Since iOS Shortcuts are binary files, you'll need to create this manually using the instructions above. Once created, you can share it via iCloud link.

Alternatively, you can use this template structure and import it via the Shortcuts app's import feature.

---

Last Updated: 2025-08-25
Compatible with: iOS 15+, n8n v1.0+