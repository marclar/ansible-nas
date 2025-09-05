# Ollama

[Ollama](https://ollama.ai/) is a local AI model server that enables running large language models locally. In Ansible-NAS, it's primarily configured to provide AI-powered automatic tagging for Karakeep bookmarks.

## Features

- Local AI model hosting (no external API dependencies)
- Support for multiple models (text and vision)
- Automatic model downloading during deployment
- Integration with Karakeep for bookmark tagging
- Optional GPU acceleration support

## Configuration

Ollama is configured in your inventory file. Key variables include:

```yaml
ollama_enabled: true
ollama_port: 11434
ollama_gpu_enabled: false  # Set to true if you have NVIDIA GPU support
```

### Model Configuration

By default, Ollama downloads:
- `llama3.2:3b` - Lightweight text model for automatic tagging
- `llava:7b` - Vision model for image analysis (optional)

You can customize models in your inventory:

```yaml
ollama_default_models:
  - "llama3.2:3b"
  - "mistral:7b"
  - "codellama:13b"
```

### Karakeep Integration

When Ollama is enabled, Karakeep automatically uses it for AI-powered features:

```yaml
karakeep_ollama_base_url: "http://ollama:11434"
karakeep_inference_text_model: "llama3.2:3b"
karakeep_inference_image_model: "llava:7b"
```

## Usage

Once deployed, Ollama runs in the background serving AI models to integrated services. You can also interact with it directly:

```bash
# List available models
curl http://your-nas:11434/api/tags

# Pull a new model
curl -X POST http://your-nas:11434/api/pull -d '{"name": "mistral:7b"}'

# Generate text
curl -X POST http://your-nas:11434/api/generate -d '{
  "model": "llama3.2:3b",
  "prompt": "Why is the sky blue?"
}'
```

## Resource Requirements

- **Memory**: Minimum 4GB allocated (configurable via `ollama_memory`)
- **Storage**: Models require 2-10GB each in `{{ ollama_data_directory }}/models`
- **CPU**: Multi-core processor recommended
- **GPU**: Optional but significantly improves performance

## Troubleshooting

If models fail to download during deployment:
1. Check network connectivity
2. Ensure sufficient disk space
3. Manually pull models: `docker exec ollama ollama pull llama3.2:3b`

For Karakeep integration issues:
1. Verify Ollama is running: `docker ps | grep ollama`
2. Check container linking in Karakeep logs
3. Ensure models are downloaded: `curl http://your-nas:11434/api/tags`