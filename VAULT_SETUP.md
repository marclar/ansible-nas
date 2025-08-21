# Ansible Vault Setup Guide

This repository uses Ansible Vault to securely store sensitive information like API tokens, passwords, and keys.

## Vault Files

- `inventories/production/group_vars/nas/vault.yml` - Production environment secrets (encrypted)
- `inventories/vm/group_vars/nas/vault.yml` - VM environment secrets (encrypted)

## Required Vault Variables

Each vault file should contain:

```yaml
---
# Cloudflare API Token for Traefik SSL certificates
vault_traefik_cf_dns_api_token: "your-cloudflare-api-token"

# Cloudflare Tunnel Token
vault_cloudflare_tunnel_token: "your-tunnel-token"

# Plex Claim Token (get from https://www.plex.tv/claim)
vault_plex_claim_token: "claim-xxxxxxxxxxxxx"

# VPN Credentials (if using VPN for download clients)
vault_vpn_username: "your-vpn-username"
vault_vpn_password: "your-vpn-password"

# Service API Keys (optional - get from each service's settings)
vault_plex_api_key: ""
vault_radarr_api_key: ""
vault_sonarr_api_key: ""
vault_bazarr_api_key: ""
vault_prowlarr_api_key: ""
vault_sabnzbd_api_key: ""
vault_portainer_api_key: ""
vault_overseerr_api_key: ""
```

## Managing Vault Files

### Create a Vault Password File

Create `.vault_pass` in the root directory with your vault password:
```bash
echo "your-secure-password" > .vault_pass
chmod 600 .vault_pass
```

**Note:** `.vault_pass` is in `.gitignore` and will NOT be committed to the repository.

### Encrypt a Vault File

```bash
ansible-vault encrypt inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

### Decrypt a Vault File (for editing)

```bash
ansible-vault decrypt inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

### Edit a Vault File

```bash
ansible-vault edit inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

### View Vault Contents (without decrypting file)

```bash
ansible-vault view inventories/vm/group_vars/nas/vault.yml --vault-password-file .vault_pass
```

## Running Playbooks with Vault

### Using Password File

```bash
ansible-playbook -i inventories/vm/inventory nas.yml --vault-password-file .vault_pass
```

### Using Password Prompt

```bash
ansible-playbook -i inventories/vm/inventory nas.yml --ask-vault-pass
```

### Using Environment Variable

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass
ansible-playbook -i inventories/vm/inventory nas.yml
```

## Security Best Practices

1. **Never commit unencrypted vault files** to the repository
2. **Use strong passwords** for vault encryption
3. **Keep vault password files secure** and never share them
4. **Rotate sensitive credentials** regularly
5. **Use different vault passwords** for different environments (production vs development)

## Cloudflare Token Requirements

### For Traefik SSL (CF_DNS_API_TOKEN)

Create a token with these permissions:
- Zone:Zone:Read
- Zone:DNS:Edit

### For Cloudflare Tunnel

Get the tunnel token from:
1. Go to https://one.dash.cloudflare.com/
2. Navigate to Zero Trust → Access → Tunnels
3. Select your tunnel
4. Click "Configure"
5. Copy the token from the install command

## Important Note for Production

The production vault (`inventories/production/group_vars/nas/vault.yml`) requires the following API token to be added:
- `vault_traefik_cf_dns_api_token`: AmxdT1N1FTxkGWG4ewvdlbcYW_EEb98rYR5IJlWb

This token was previously hardcoded and needs to be moved to the vault before deploying to production.