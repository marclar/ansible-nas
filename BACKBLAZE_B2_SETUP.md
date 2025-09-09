# Backblaze B2 Cloud Backup Setup Guide

This guide explains how to configure Backblaze B2 cloud storage backup for your Ansible-NAS deployment. The service automatically syncs your local Restic backups to Backblaze B2 cloud storage.

## Overview

The Backblaze B2 backup service:
- Uses rclone to sync `/mnt/truenas-media/backups` to Backblaze B2
- Runs daily at 3 AM (before Restic local backup at 5 AM)
- Supports incremental sync to minimize bandwidth usage
- Includes health checks and optional notifications
- Provides secure encrypted transfer to cloud storage

## Prerequisites

1. **Backblaze B2 Account**: Sign up at https://www.backblaze.com/b2/cloud-storage.html
2. **Existing Local Backups**: Ensure Restic backup service is already configured and creating backups

## Step 1: Create Backblaze B2 Account and Bucket

1. Sign up for a Backblaze B2 account at https://www.backblaze.com/b2/ ✅
2. Log into your Backblaze account ✅
3. **Bucket Already Created**: `1815-ansible-nas` ✅
   - Bucket Type: Private (recommended)
   - The configuration has been updated to use this bucket

## Step 2: Generate Application Keys

1. Go to "Account" → "Application Keys"
2. Click "Add a New Application Key"
3. Key Configuration:
   - **Key Name**: `ansible-nas-backup-key` (or your preferred name)
   - **Allow access to Bucket(s)**: Select your bucket (`1815-ansible-nas`)
   - **Type of Access**: Read and Write
   - **Allow List All Bucket Names**: Yes (recommended)
4. Click "Create New Key"
5. **IMPORTANT**: Copy both the **keyID** and **applicationKey** - you won't see the applicationKey again!

## Step 3: Configure Ansible-NAS

### Update Vault with Credentials

1. Edit the encrypted vault file:
   ```bash
   ansible-vault edit inventories/production/group_vars/nas/vault.yml --vault-password-file=.vault_pass
   ```

2. Replace the placeholder values:
   ```yaml
   # Replace these with your actual Backblaze B2 credentials
   vault_backblaze_b2_application_key_id: "YOUR_KEY_ID_HERE"
   vault_backblaze_b2_application_key: "YOUR_APPLICATION_KEY_HERE"
   ```

### Verify Configuration

The service is already configured in `inventories/production/group_vars/nas/main.yml`:

```yaml
###
### Backblaze B2 Cloud Backup Configuration
###
backblaze_b2_enabled: true
backblaze_b2_bucket_name: "1815-ansible-nas"
backblaze_b2_sync_schedule: "0 3 * * *"  # Daily at 3 AM
backblaze_b2_bandwidth_limit: "0"  # Unlimited
backblaze_b2_log_level: "INFO"
backblaze_b2_notification_url: ""  # Optional webhook URL
backblaze_b2_retention_days: "90"  # Keep backups for 90 days
```

## Step 4: Deploy the Service

1. Deploy the Backblaze B2 backup service:
   ```bash
   ansible-playbook -i inventories/production/inventory nas.yml --vault-password-file=.vault_pass --tags "backblaze-b2"
   ```

2. Check the deployment:
   ```bash
   ssh mk@192.168.12.211 "docker ps | grep backblaze-b2"
   ```

## Step 5: Verify the Setup

### Test Connection
```bash
# Test Backblaze B2 connection
ssh mk@192.168.12.211 "docker exec backblaze-b2 rclone --config /config/rclone.conf lsd backblaze-b2:"
```

### Manual Sync Test
```bash
# Trigger an immediate sync
ssh mk@192.168.12.211 "docker exec backblaze-b2 /scripts/sync-to-b2.sh"
```

### Monitor Logs
```bash
# Check sync logs
ssh mk@192.168.12.211 "docker exec backblaze-b2 tail -f /logs/rclone.log"
```

## Configuration Options

### Bandwidth Limiting
If you need to limit bandwidth usage, update the configuration:
```yaml
backblaze_b2_bandwidth_limit: "10240"  # 10 MB/s limit
```

### Notification Webhooks
To receive sync notifications, add a webhook URL:
```yaml
backblaze_b2_notification_url: "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"
```

### Custom Sync Schedule
Modify the sync schedule (cron format):
```yaml
backblaze_b2_sync_schedule: "0 2 * * *"  # Daily at 2 AM
```

## Monitoring and Maintenance

### Check Sync Status
```bash
# View last sync results
ssh mk@192.168.12.211 "docker exec backblaze-b2 tail -20 /logs/rclone.log"
```

### Container Health
```bash
# Check container status
ssh mk@192.168.12.211 "docker exec backblaze-b2 /scripts/health-check.sh"
```

### Storage Usage
Monitor your Backblaze B2 storage usage in the B2 web interface under "B2 Cloud Storage" → "Buckets".

## Troubleshooting

### Connection Issues
1. Verify credentials are correct in the vault
2. Check that the bucket name matches exactly
3. Ensure bucket permissions allow read/write access

### Sync Failures
1. Check logs: `docker exec backblaze-b2 tail -f /logs/rclone.log`
2. Verify source directory has files: `ls -la /mnt/truenas-media/backups`
3. Test manual sync: `docker exec backblaze-b2 /scripts/sync-to-b2.sh`

### Network/Bandwidth Issues
1. Add bandwidth limiting if upload speeds are too high
2. Check that your network doesn't block outbound connections to Backblaze
3. Monitor transfer progress in the logs

## Cost Considerations

Backblaze B2 pricing (as of 2025):
- Storage: $6/TB/month
- Download: $10/TB (first 3x storage amount per month is free)
- API calls: Free for most operations

For a typical home server with 500GB of backups:
- Monthly storage cost: ~$3
- No download costs for normal operations

## Security

- All data is transferred over HTTPS/TLS
- Credentials are stored encrypted in Ansible Vault
- Container runs with minimal privileges
- Source directory is mounted read-only for safety

## Integration with Restic

The Backblaze B2 service complements the local Restic backup:
- **Restic**: Creates encrypted, deduplicated local backups at 5 AM
- **Backblaze B2**: Syncs these backups to cloud storage at 3 AM
- This provides both local and offsite backup protection

The service creates a complete offsite backup strategy for your Ansible-NAS deployment.