# Output values for Free Tier Code-Server Deployment

# ========================================
# Instance Information
# ========================================

output "instance_id" {
  description = "OCID of the compute instance"
  value       = oci_core_instance.main.id
}

output "instance_state" {
  description = "State of the compute instance"
  value       = oci_core_instance.main.state
}

output "instance_shape" {
  description = "Shape of the compute instance"
  value       = oci_core_instance.main.shape
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.main.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the instance (if assigned)"
  value       = var.enable_cloudflare_tunnel ? "N/A (using Cloudflare Tunnel)" : oci_core_instance.main.public_ip
}

# ========================================
# Network Information
# ========================================

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.main.id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = oci_core_subnet.main.id
}

# ========================================
# Storage Information
# ========================================

output "boot_volume_id" {
  description = "OCID of the boot volume"
  value       = oci_core_instance.main.boot_volume_id
}

output "data_volume_id" {
  description = "OCID of the data volume (if created)"
  value       = var.create_data_volume ? oci_core_volume.data[0].id : null
}

output "data_volume_size_gb" {
  description = "Size of the data volume in GB"
  value       = var.create_data_volume ? var.data_volume_size_gb : null
}

# ========================================
# Access Information
# ========================================

output "access_url" {
  description = "URL to access code-server"
  value = var.enable_cloudflare_tunnel ? 
    "https://${var.cloudflare_subdomain}.${var.cloudflare_domain}" :
    var.enable_https ? 
      "https://${oci_core_instance.main.public_ip}" :
      "http://${oci_core_instance.main.public_ip}"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value = var.enable_cloudflare_tunnel ? 
    "SSH via Cloudflare Tunnel - see documentation" :
    "ssh -i ${var.ssh_public_key == "" ? "${path.module}/ssh-keys/${local.name_prefix}-private-key.pem" : "your-private-key"} ubuntu@${oci_core_instance.main.public_ip}"
}

# ========================================
# Cloudflare Information
# ========================================

output "cloudflare_tunnel_id" {
  description = "Cloudflare tunnel ID (if enabled)"
  value       = var.enable_cloudflare_tunnel ? cloudflare_tunnel.main[0].id : null
  sensitive   = true
}

output "cloudflare_tunnel_token" {
  description = "Cloudflare tunnel token for connecting (if enabled)"
  value       = var.enable_cloudflare_tunnel ? cloudflare_tunnel.main[0].tunnel_token : null
  sensitive   = true
}

output "cloudflare_access_app_id" {
  description = "Cloudflare Access application ID (if enabled)"
  value       = var.enable_cloudflare_tunnel ? cloudflare_access_application.main[0].id : null
}

output "cloudflare_domain" {
  description = "Full domain name for code-server access (if Cloudflare enabled)"
  value       = var.enable_cloudflare_tunnel ? "${var.cloudflare_subdomain}.${var.cloudflare_domain}" : null
}

# ========================================
# SSH Key Information
# ========================================

output "ssh_private_key_path" {
  description = "Path to generated SSH private key (if generated and saved)"
  value       = var.ssh_public_key == "" && var.save_ssh_key ? "${path.module}/ssh-keys/${local.name_prefix}-private-key.pem" : null
}

output "ssh_public_key_path" {
  description = "Path to generated SSH public key (if generated and saved)"
  value       = var.ssh_public_key == "" && var.save_ssh_key ? "${path.module}/ssh-keys/${local.name_prefix}-public-key.pub" : null
}

output "ssh_public_key_content" {
  description = "SSH public key content"
  value       = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.ssh[0].public_key_openssh
}

# ========================================
# Configuration Summary
# ========================================

output "configuration_summary" {
  description = "Summary of the deployment configuration"
  value = {
    project_name           = var.project_name
    environment           = var.environment
    oci_region           = var.oci_region
    instance_shape       = local.instance_shape
    instance_ocpus       = local.instance_ocpus
    instance_memory_gb   = local.instance_memory_gb
    use_always_free      = var.use_always_free
    enable_preemptible   = var.enable_preemptible
    boot_volume_size_gb  = var.boot_volume_size_gb
    data_volume_size_gb  = var.create_data_volume ? var.data_volume_size_gb : 0
    enable_cloudflare    = var.enable_cloudflare_tunnel
    enable_https         = var.enable_https
    codeserver_version   = var.codeserver_version
    enable_backups       = var.enable_backups
  }
}

# ========================================
# Cost Information
# ========================================

output "estimated_monthly_cost" {
  description = "Estimated monthly cost breakdown"
  value = {
    compute     = var.use_always_free ? "$0 (Always Free)" : "Variable (depending on usage)"
    storage     = "${var.boot_volume_size_gb + (var.create_data_volume ? var.data_volume_size_gb : 0)}GB - $0 (within 200GB free tier)"
    network     = "$0 (basic networking included)"
    cloudflare  = var.enable_cloudflare_tunnel ? "$20/month (Cloudflare paid plan required)" : "$0"
    total_min   = var.enable_cloudflare_tunnel ? "$20/month" : "$0/month"
    note        = "Costs assume staying within OCI Always Free tier limits"
  }
}

# ========================================
# Next Steps
# ========================================

output "next_steps" {
  description = "Next steps after deployment"
  value = [
    "1. Wait for instance to fully initialize (5-10 minutes)",
    "2. Access code-server at: ${var.enable_cloudflare_tunnel ? "https://${var.cloudflare_subdomain}.${var.cloudflare_domain}" : var.enable_https ? "https://${oci_core_instance.main.public_ip}" : "http://${oci_core_instance.main.public_ip}"}",
    var.enable_cloudflare_tunnel ? "3. Authenticate using your configured email address" : "3. Use the default code-server authentication",
    "4. Open folder: /home/${var.codeserver_user}/workspace for your projects",
    var.create_data_volume ? "5. Your workspace data is persisted on the data volume" : "5. Consider enabling data volume for workspace persistence",
    "6. SSH access: ${var.enable_cloudflare_tunnel ? "Configure SSH over Cloudflare Tunnel" : "ssh -i your-key ubuntu@${oci_core_instance.main.public_ip}"}",
    "7. Monitor instance health and storage usage",
    var.enable_preemptible ? "8. Note: Instance is preemptible and may be terminated by OCI" : "8. Instance will run continuously within free tier limits"
  ]
}