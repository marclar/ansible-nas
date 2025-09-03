# autobrr

autobrr is a modern, fast, and easy to configure RSS downloader/race client that can be configured to automatically grab torrents based on filters and send them to qBittorrent, Deluge, Transmission, or rTorrent.

Homepage: https://autobrr.com/
Documentation: https://autobrr.com/installation
GitHub: https://github.com/autobrr/autobrr

## Usage

Set `autobrr_enabled: true` in your inventories/<your_inventory>/group_vars/nas.yml file.

The autobrr web interface will be accessible at http://ansible_nas_host_or_ip:7474 (or https://autobrr.your-domain.com if you configure Traefik with a domain).

## Specific Configuration

Key variables:
- `autobrr_data_directory`: Directory for autobrr configuration files
- `autobrr_port`: Web interface port (default: 7474)
- `autobrr_user_id` and `autobrr_group_id`: User/group for file permissions
- `autobrr_hostname`: Hostname for Traefik routing

## Docker Image

This role uses the official `ghcr.io/autobrr/autobrr:latest` Docker image.

## Features

- RSS/IRC monitoring for releases
- Advanced filtering system
- Integration with download clients (qBittorrent, Deluge, Transmission, rTorrent)
- Cross-seed support
- WebUI for configuration
- API support for external integrations