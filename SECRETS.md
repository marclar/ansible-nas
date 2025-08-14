# Secrets Management for Ansible-NAS

This project uses Ansible Vault to securely manage sensitive data like API keys, passwords, and tokens.

## Setup Instructions

### 1. Create Your Vault Password File

Create a file named `.vault_pass` in the project root with a strong password:

```bash
echo "your-strong-password-here" > .vault_pass
chmod 600 .vault_pass
```

**Important:** 
- Never commit `.vault_pass` to git (it's in .gitignore)
- Keep this password secure - you'll need it to decrypt the vault

### 2. Edit Encrypted Secrets

To edit the encrypted vault file:

```bash
ansible-vault edit inventories/production/group_vars/vault.yml --vault-password-file .vault_pass
```

Or set the environment variable to avoid typing it each time:

```bash
export ANSIBLE_VAULT_PASSWORD_FILE=.vault_pass
ansible-vault edit inventories/production/group_vars/vault.yml
```

### 3. View Encrypted Secrets

To view the contents without editing:

```bash
ansible-vault view inventories/production/group_vars/vault.yml --vault-password-file .vault_pass
```

### 4. Running Playbooks

When running playbooks, include the vault password:

```bash
# Using password file
ansible-playbook -i inventories/production/inventory nas.yml --vault-password-file .vault_pass

# Or using the deploy script (updated to use vault)
./deploy.sh
```

## Secrets Structure

The vault file (`inventories/production/group_vars/vault.yml`) contains:

- **Cloudflare Credentials:**
  - `vault_cloudflare_tunnel_token`: Cloudflare Tunnel token

- **Media Server API Keys:**
  - `vault_plex_api_key`: Plex API key for widgets
  - `vault_radarr_api_key`: Radarr API key
  - `vault_sonarr_api_key`: Sonarr API key
  - `vault_sabnzbd_api_key`: SABnzbd API key

- **VPN Credentials:**
  - `vault_gluetun_openvpn_user`: VPN username
  - `vault_gluetun_openvpn_password`: VPN password
  - `vault_gluetun_wireguard_private_key`: WireGuard private key (if using)
  - `vault_gluetun_wireguard_addresses`: WireGuard addresses (if using)

## Adding New Secrets

1. Edit the vault file:
   ```bash
   ansible-vault edit inventories/production/group_vars/vault.yml --vault-password-file .vault_pass
   ```

2. Add your new secret with the `vault_` prefix:
   ```yaml
   vault_new_api_key: "your-secret-value"
   ```

3. Reference it in your configuration files:
   ```yaml
   some_service_api_key: "{{ vault_new_api_key }}"
   ```

## Rotating Secrets

To change the vault password:

```bash
ansible-vault rekey inventories/production/group_vars/vault.yml \
  --vault-password-file .vault_pass \
  --new-vault-password-file .new_vault_pass
```

## Alternative: Using Environment Variables

If you prefer environment variables over a password file:

```bash
# Set the password in your shell
export ANSIBLE_VAULT_PASSWORD="your-vault-password"

# Run playbooks
ansible-playbook -i inventories/production/inventory nas.yml --vault-pass-file <(echo $ANSIBLE_VAULT_PASSWORD)
```

## Security Best Practices

1. **Never commit unencrypted secrets** to version control
2. **Use strong passwords** for the vault
3. **Rotate secrets regularly**
4. **Limit access** to the vault password
5. **Use different vaults** for different environments (production, staging, etc.)
6. **Backup your vault password** securely (password manager, etc.)

## Troubleshooting

### "Attempting to decrypt but no vault secrets found"
- Ensure you're providing the vault password via `--vault-password-file` or environment variable

### "ERROR! Decryption failed"
- Check that your vault password is correct
- Ensure the vault file hasn't been corrupted

### "Permission denied" when reading .vault_pass
- Fix permissions: `chmod 600 .vault_pass`