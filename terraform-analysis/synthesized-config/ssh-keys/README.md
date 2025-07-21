# SSH Keys Directory

This directory will contain auto-generated SSH keys when `save_ssh_key = true` and `ssh_public_key = ""`.

Generated files:
- `[project-name]-[environment]-private-key.pem` - SSH private key (600 permissions)
- `[project-name]-[environment]-public-key.pub` - SSH public key (644 permissions)

## Security Notes

- Private keys are generated with 4096-bit RSA encryption
- Files are automatically created with secure permissions
- Keys are excluded from version control via .gitignore
- Backup your private key securely before destroying the Terraform state

## Usage

```bash
# Connect to instance
ssh -i ssh-keys/my-code-server-dev-private-key.pem ubuntu@[INSTANCE_IP]

# Copy public key for manual use
cat ssh-keys/my-code-server-dev-public-key.pub
```