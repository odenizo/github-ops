# Free Tier Code-Server Terraform Configuration

This directory contains a synthesized Terraform configuration for deploying code-server on Oracle Cloud Infrastructure's Always Free tier, with optional Cloudflare Tunnel integration for secure access.

## Overview

This configuration combines the best practices from multiple analyzed repositories:
- **oracle-devrel/terraform-oci-code-server**: OCI Always Free tier optimization
- **timoa/terraform-oci-vscode-server**: Cloudflare Tunnel integration
- **bvilnis/terraform-aws-code-server**: Professional authentication patterns
- **aws-samples/sample-developer-environment**: Enterprise security practices

## Features

- ✅ **Free Tier Optimized**: Designed for OCI Always Free tier (zero cost)
- ✅ **Cloudflare Integration**: Optional Zero Trust access via Cloudflare Tunnel
- ✅ **Persistent Storage**: Separate data volume for workspace persistence
- ✅ **Automatic Backups**: Configurable backup policies
- ✅ **Security Focused**: Private networking with controlled access
- ✅ **ARM Support**: Efficient ARM-based instances (4 vCPU, 24GB RAM)
- ✅ **Auto-HTTPS**: Let's Encrypt integration for custom domains

## Quick Start

### 1. Prerequisites

- Oracle Cloud Infrastructure account (free tier)
- Terraform >= 1.0 installed
- (Optional) Cloudflare account with paid plan for Tunnel feature
- (Optional) Domain managed by Cloudflare

### 2. Basic Deployment (Free Tier Only)

```bash
# Clone the repository
git clone <repository-url>
cd terraform-analysis/synthesized-config

# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your OCI credentials
vim terraform.tfvars

# Initialize and deploy
terraform init
terraform plan
terraform apply
```

### 3. Environment Variables (Recommended)

Set sensitive values as environment variables:

```bash
export TF_VAR_oci_tenancy_ocid="ocid1.tenancy.oc1..xxxxx"
export TF_VAR_oci_compartment_ocid="ocid1.compartment.oc1..xxxxx"
export TF_VAR_oci_user_ocid="ocid1.user.oc1..xxxxx"
export TF_VAR_oci_fingerprint="xx:xx:xx:xx:xx"
export TF_VAR_oci_private_key="$(cat ~/.oci/oci_api_key.pem)"

# For Cloudflare (if using tunnel)
export TF_VAR_cloudflare_api_token="your_cloudflare_api_token"
export TF_VAR_cloudflare_account_id="your_cloudflare_account_id"
```

## Configuration Options

### Always Free Deployment

```hcl
# Minimal free tier configuration
use_always_free     = true
instance_ocpus      = 1    # Fixed for free tier
instance_memory_gb  = 1    # Fixed for free tier
boot_volume_size_gb = 50   # Within free limits
data_volume_size_gb = 100  # Within 200GB total limit
enable_cloudflare_tunnel = false  # Avoid Cloudflare costs
```

### High-Performance Free Deployment

```hcl
# ARM-based high performance (still free)
use_always_free     = false
instance_shape      = "VM.Standard.A1.Flex"  # Auto-selected
instance_ocpus      = 4    # ARM: 4 vCPU free
instance_memory_gb  = 24   # ARM: 24GB RAM free
boot_volume_size_gb = 50
data_volume_size_gb = 150  # Up to 200GB total
```

### Enterprise with Cloudflare

```hcl
# Secure access with Zero Trust
enable_cloudflare_tunnel = true
cloudflare_domain = "yourdomain.com"
cloudflare_subdomain = "ide"
cloudflare_allowed_emails = ["team@yourdomain.com"]
```

## Cost Analysis

### OCI Always Free Tier
- **Compute**: $0/month (Always Free)
- **Storage**: $0/month (200GB included)
- **Network**: $0/month (basic networking included)
- **Total**: $0/month

### Cloudflare Add-on
- **Tunnel**: $20/month (requires paid Cloudflare plan)
- **Access**: $0 (included with paid plan)
- **DNS**: $0 (if domain managed by Cloudflare)

### Alternative: Free-Only Approach
Set `enable_cloudflare_tunnel = false` for completely free deployment:
- Uses public IP with Let's Encrypt for HTTPS
- Password-based authentication
- Still secure with proper firewall rules

## Security Features

### Network Security
- Private subnet option with Cloudflare Tunnel
- Configurable SSH access restrictions
- Firewall rules for minimal exposure

### Authentication
- **Cloudflare Access**: Email-based Zero Trust authentication
- **Password Auth**: Secure random password generation
- **SSH Keys**: Automatic key generation or bring your own

### Data Protection
- Encrypted storage volumes
- Automatic backup policies
- Persistent workspace data

## File Structure

```
├── main.tf                    # Main infrastructure configuration
├── variables.tf               # Input variables with validation
├── outputs.tf                 # Output values and next steps
├── terraform.tfvars.example   # Example configuration
├── templates/
│   └── cloud-init.yaml       # Instance initialization script
└── ssh-keys/                 # Generated SSH keys (if enabled)
    ├── project-private-key.pem
    └── project-public-key.pub
```

## Usage Examples

### 1. Basic Free Tier Deployment

```bash
terraform apply -var="use_always_free=true" -var="enable_cloudflare_tunnel=false"
```

### 2. High-Performance Free Deployment

```bash
terraform apply -var="use_always_free=false" -var="instance_ocpus=4" -var="instance_memory_gb=24"
```

### 3. Enterprise with Cloudflare

```bash
terraform apply \
  -var="enable_cloudflare_tunnel=true" \
  -var="cloudflare_domain=yourdomain.com" \
  -var="cloudflare_allowed_emails=[\"you@yourdomain.com\"]"
```

## Post-Deployment

After successful deployment:

1. **Access Code-Server**:
   - Cloudflare: `https://ide.yourdomain.com`
   - Direct: `http://[INSTANCE_IP]`

2. **Get Password**:
   ```bash
   ssh -i ssh-keys/project-private-key.pem ubuntu@[INSTANCE_IP]
   cat /home/coder/code-server-password.txt
   ```

3. **Open Workspace**:
   - Navigate to `/home/coder/workspace` in code-server
   - Your projects will persist on the data volume

4. **SSH Access**:
   ```bash
   ssh -i ssh-keys/project-private-key.pem ubuntu@[INSTANCE_IP]
   ```

## Monitoring & Maintenance

### Check Instance Status
```bash
# Via Terraform
terraform show | grep instance_state

# Via OCI CLI
oci compute instance list --compartment-id [COMPARTMENT_OCID]
```

### Backup Verification
```bash
# List volume backups
oci bv backup list --compartment-id [COMPARTMENT_OCID]
```

### Update Code-Server
```bash
# SSH to instance
curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl restart code-server@coder
```

## Troubleshooting

### Common Issues

1. **Instance not accessible**:
   - Check security group rules
   - Verify public IP assignment
   - Confirm code-server service status

2. **Cloudflare Tunnel not working**:
   - Verify API token permissions
   - Check tunnel service status: `systemctl status cloudflared`
   - Confirm DNS propagation

3. **Storage not mounted**:
   - Check volume attachment: `lsblk`
   - Verify mount points: `df -h`
   - Review cloud-init logs: `/var/log/cloud-init-output.log`

### Log Locations
- Cloud-init: `/var/log/cloud-init-output.log`
- Code-server: `journalctl -u code-server@coder`
- Cloudflared: `journalctl -u cloudflared`
- Nginx: `/var/log/nginx/`

## Cleanup

```bash
# Destroy all resources
terraform destroy

# Remove local files
rm -rf ssh-keys/
rm terraform.tfvars
```

## Contributing

This configuration is synthesized from multiple open-source repositories. Contributions should:
- Maintain free tier compatibility
- Follow Terraform best practices
- Include proper documentation
- Test on OCI Always Free tier

## License

Based on configurations from:
- oracle-devrel/terraform-oci-code-server (UPL-1.0)
- bvilnis/terraform-aws-code-server (Apache-2.0)
- timoa/terraform-oci-vscode-server (Apache-2.0)
- aws-samples/sample-developer-environment (MIT-0)

See respective repositories for detailed license information.