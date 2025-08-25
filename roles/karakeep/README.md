# Karakeep - AI-Powered Bookmarking System

Karakeep is a self-hostable "bookmark everything" application that uses AI for automatically tagging your saved content.

## Features

- 🔖 Bookmark links, notes, and images
- 🤖 AI-powered automatic tagging (with OpenAI or local Ollama models)
- 🔍 Full-text search powered by Meilisearch
- 📱 Browser extensions and mobile apps available
- 🔌 REST API for integrations
- 🎨 Modern, responsive UI built with NextJS

## Configuration

### Basic Setup

```yaml
karakeep_enabled: true
karakeep_available_externally: true

# Generate secure keys with:
# openssl rand -base64 32
karakeep_nextauth_secret: "your-secret-here"
karakeep_meili_master_key: "your-key-here"
```

### AI Features (Optional)

For automatic tagging, configure either OpenAI or Ollama:

#### OpenAI
```yaml
karakeep_openai_api_key: "sk-..."
```

#### Local Ollama
```yaml
karakeep_ollama_base_url: "http://ollama:11434"
karakeep_inference_text_model: "llama2"
karakeep_inference_image_model: "llava"
karakeep_inference_context_length: "2048"
```

## Architecture

Karakeep runs as three containers:
1. **karakeep** - Main application server (port 3000)
2. **karakeep-meilisearch** - Search engine backend
3. **karakeep-chrome** - Headless Chrome for web scraping

## Default Credentials

No default credentials. Create your account on first access at:
- https://karakeep.{{ ansible_nas_domain }}/signup

## Usage

1. Navigate to https://karakeep.{{ ansible_nas_domain }}
2. Create an account
3. Start bookmarking:
   - Paste URLs directly
   - Write notes
   - Drag and drop images
   - Use browser extension (download from Karakeep dashboard)

## Data Storage

All data is stored in:
- `{{ karakeep_data_directory }}/data` - Application data
- `{{ karakeep_data_directory }}/meilisearch` - Search index

## API Access

Karakeep provides a REST API for integrations. Access documentation at:
- https://docs.karakeep.app/

## Browser Extensions

Available for:
- Chrome/Edge
- Firefox
- Safari

Download from the settings page after logging in.

## Troubleshooting

### Container not starting
Check logs:
```bash
docker logs karakeep
docker logs karakeep-meilisearch
docker logs karakeep-chrome
```

### Search not working
Ensure Meilisearch container is running and healthy:
```bash
docker exec karakeep-meilisearch curl -s http://localhost:7700/health
```

### Chrome scraping issues
The Chrome container may need more memory. Increase in defaults:
```yaml
karakeep_chrome_memory: 1g
```

## External Links

- [GitHub Repository](https://github.com/karakeep-app/karakeep)
- [Documentation](https://docs.karakeep.app)
- [Demo Instance](https://try.karakeep.app)