# Backblaze B2 Cloud Backup

This role deploys a Backblaze B2 cloud backup service using rclone to sync local backups to cloud storage.

## Overview

- **Container**: rclone/rclone:latest
- **Purpose**: Sync local Restic backups to Backblaze B2 cloud storage
- **Schedule**: Daily at 3 AM (configurable)
- **Bandwidth**: Configurable limits to prevent network saturation
- **Security**: Encrypted transfer, read-only source mount

## Features

- **Incremental Sync**: Only uploads changed files to minimize bandwidth
- **Scheduled Backups**: Automated daily sync via cron
- **Health Monitoring**: Built-in health checks and optional notifications
- **Bandwidth Control**: Configurable upload speed limits
- **Secure Configuration**: Credentials stored in Ansible Vault

## Requirements

- Backblaze B2 account and bucket
- Application Key ID and Application Key
- Local backups directory (typically from Restic)

## Configuration

### Required Variables

```yaml
backblaze_b2_enabled: true
backblaze_b2_application_key_id: "{{ vault_backblaze_b2_application_key_id }}"
backblaze_b2_application_key: "{{ vault_backblaze_b2_application_key }}"
backblaze_b2_bucket_name: "your-bucket-name"
```

### Optional Variables

```yaml
backblaze_b2_sync_schedule: "0 3 * * *"  # Daily at 3 AM
backblaze_b2_bandwidth_limit: "0"  # Unlimited (KB/s)
backblaze_b2_log_level: "INFO"
backblaze_b2_source_path: "/mnt/truenas-media/backups"
backblaze_b2_notification_url: ""  # Webhook for notifications
```

## Usage

1. Create Backblaze B2 account and bucket
2. Generate Application Key with read/write access
3. Store credentials in Ansible Vault
4. Configure bucket name and options
5. Deploy with Ansible

## Commands

```bash
# Deploy service
ansible-playbook nas.yml --tags "backblaze-b2"

# Test connection
docker exec backblaze-b2 rclone --config /config/rclone.conf lsd backblaze-b2:

# Manual sync
docker exec backblaze-b2 /scripts/sync-to-b2.sh

# Check logs
docker exec backblaze-b2 tail -f /logs/rclone.log
```

## File Structure

```
/home/mk/docker/backblaze-b2/
├── config/
│   └── rclone.conf          # rclone configuration with B2 credentials
├── logs/
│   └── rclone.log           # Sync operation logs
├── sync-to-b2.sh            # Main sync script
└── health-check.sh          # Health monitoring script
```

## Integration

This service is designed to work with the Restic backup role:
- Restic creates local encrypted backups at 5 AM
- Backblaze B2 syncs these to cloud at 3 AM (previous day's backups)
- Provides complete local + offsite backup solution

## Monitoring

The service includes health checks and logging:
- Sync results logged to `/logs/rclone.log`
- Optional webhook notifications on success/failure
- Health check script verifies recent backup activity

## Security

- Credentials encrypted in Ansible Vault
- Source directory mounted read-only
- Encrypted transfer to Backblaze B2
- Minimal container privileges