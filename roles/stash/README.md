# Ansible Role: Stash

This role installs and configures [Stash](https://github.com/stashapp/stash) - an organizer for your adult content.

## Features

Stash is a self-hosted web application for organizing and viewing your adult media content. It provides:
- Automatic scanning and tagging of video files
- Scene management with performers, tags, and studios
- Gallery support for images
- Powerful filtering and search capabilities
- Video streaming with scrubbing preview
- Metadata scraping from various sources

## Configuration

The role can be configured via the following variables in your inventory:

```yaml
stash_enabled: true
stash_available_externally: true
```

## Default Ports

- Web UI: 9999

## Data Directories

The following directories are created and mounted:
- `/docker/stash/config` - Configuration files
- `/docker/stash/media` - Media library location
- `/docker/stash/metadata` - Metadata storage
- `/docker/stash/cache` - Cache files
- `/docker/stash/generated` - Generated content (thumbnails, previews, etc.)

## Access

Once deployed, Stash will be available at:
- Local: `http://<server-ip>:9999`
- External: `https://stash.<your-domain>` (if configured with Traefik)

## First Time Setup

On first launch, Stash will guide you through:
1. Setting up your library paths
2. Configuring scan options
3. Setting up scrapers
4. Initial library scan

## Integration with TrueNAS

The role automatically mounts `/mnt/truenas-media` to allow access to your NAS storage.