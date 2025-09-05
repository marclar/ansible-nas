# Listmonk Database Safety Guide

## 🚨 CRITICAL: Preventing Database Overwrites

This document outlines the safety mechanisms implemented to prevent Listmonk database overwrites during deployments.

## Problem Identified

The original Listmonk role could potentially overwrite the database during redeployments due to:
1. No checks for existing database volumes
2. Container recreation without data persistence checks
3. Automatic initialization running even when database exists
4. No automatic backups before deployments

## Safety Mechanisms Implemented

### 1. Pre-Deployment Checks
- **Database Volume Check**: Verifies if `{{ listmonk_db_directory }}/PG_VERSION` exists
- **Container Status Check**: Determines if database container is already running
- **Schema Verification**: Checks for existing Listmonk tables before any initialization

### 2. Automatic Backup System
```yaml
Location: {{ listmonk_data_directory }}/auto_backups/
Format: listmonk_YYYYMMDD_HHMMSS.sql.gz
Retention: 
  - 10 most recent uncompressed backups
  - 30 most recent compressed backups
```

**Backup Triggers:**
- Before every deployment (if database exists)
- Before stopping services
- Manual backup available via playbook

### 3. Container Management Settings

**Critical Docker Settings:**
```yaml
recreate: false        # Never recreate database container
keep_volumes: true     # Always preserve volumes
comparisons:
  image: strict       # Only update on actual image changes
  env: strict        # Prevent unnecessary restarts
```

### 4. Database Initialization Guards

The database is ONLY initialized when:
- No PG_VERSION file exists in the data directory
- No Listmonk schema tables exist (subscribers, campaigns, lists)
- This is explicitly a new installation

## Manual Operations

### Creating a Manual Backup
```bash
# From the Ansible control node
ssh mk@192.168.12.208 "docker exec listmonk-db pg_dump -U listmonk listmonk" > listmonk_backup_$(date +%Y%m%d).sql
```

### Restoring from Backup
```bash
# Stop application (keep database running)
docker stop listmonk

# Restore database
docker exec -i listmonk-db psql -U listmonk listmonk < backup_file.sql

# Restart application
docker start listmonk
```

### Checking Database Status
```bash
# Check if database exists
ssh mk@192.168.12.208 "ls -la /home/mk/docker/listmonk-db/PG_VERSION"

# Check table counts
ssh mk@192.168.12.208 "docker exec listmonk-db psql -U listmonk -d listmonk -c 'SELECT COUNT(*) FROM subscribers;'"

# List recent backups
ssh mk@192.168.12.208 "ls -lht /home/mk/docker/listmonk/auto_backups/ | head -10"
```

## Deployment Best Practices

### ✅ SAFE Deployment
```bash
# This will preserve existing data
ansible-playbook -i inventories/production/inventory nas.yml --tags "listmonk" --vault-password-file=.vault_pass
```

### ⚠️ DANGEROUS Operations to Avoid
```bash
# DO NOT manually remove the database volume
rm -rf /home/mk/docker/listmonk-db  # NEVER DO THIS

# DO NOT force recreate the database container
docker rm -f listmonk-db  # AVOID THIS

# DO NOT run initialization on existing database
./listmonk --install --yes  # CHECK FIRST
```

## Recovery Procedures

### If Data Loss Occurs

1. **Stop all services immediately**
   ```bash
   docker stop listmonk listmonk-db
   ```

2. **Check for automatic backups**
   ```bash
   ls -lht /home/mk/docker/listmonk/auto_backups/
   ```

3. **Restore most recent backup**
   ```bash
   # Start only the database
   docker start listmonk-db
   
   # Restore
   zcat /home/mk/docker/listmonk/auto_backups/listmonk_YYYYMMDD_HHMMSS.sql.gz | \
     docker exec -i listmonk-db psql -U listmonk listmonk
   
   # Start application
   docker start listmonk
   ```

## Configuration Variables

Key variables that affect database persistence:

```yaml
# Database storage location (NEVER CHANGE after initial setup)
listmonk_db_directory: "{{ docker_home }}/listmonk-db"

# Application data and backups
listmonk_data_directory: "{{ docker_home }}/listmonk"

# Database credentials (changing these won't affect existing database)
listmonk_db_user: "listmonk"
listmonk_db_password: "{{ vault_listmonk_db_password }}"
listmonk_db_name: "listmonk"
```

## Monitoring and Alerts

### Health Checks
- Database connection test on every deployment
- Schema verification before initialization
- Backup size verification
- Application health endpoint monitoring

### Warning Signs
- Empty backup files
- Missing PG_VERSION file
- Sudden drop in subscriber count
- Database connection errors

## Migration to Safe Version

To migrate from the unsafe to safe version:

1. **Create manual backup first**
2. **Copy main_safe.yml to main.yml**
   ```bash
   cp roles/listmonk/tasks/main_safe.yml roles/listmonk/tasks/main.yml
   ```
3. **Run deployment with extra verbosity**
   ```bash
   ansible-playbook -i inventories/production/inventory nas.yml \
     --tags "listmonk" --vault-password-file=.vault_pass -vv
   ```
4. **Verify data integrity**

## Support and Troubleshooting

If you encounter any issues:

1. Check the automatic backups first
2. Review the deployment logs for safety check results
3. Verify database volume permissions
4. Ensure Docker has sufficient disk space

---

**Last Updated**: September 2025
**Version**: 2.0 (Safe Mode)
**Critical**: This version includes multiple safeguards against data loss