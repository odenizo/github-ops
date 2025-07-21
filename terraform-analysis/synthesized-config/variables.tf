# Variables for Free Tier Code-Server Deployment

# ========================================
# Project Configuration
# ========================================

variable "project_name" {
  description = "Name of the project (used for resource naming)"
  type        = string
  default     = "code-server"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ========================================
# OCI Configuration
# ========================================

variable "oci_region" {
  description = "OCI region where resources will be created"
  type        = string
  default     = "us-ashburn-1"
}

variable "oci_tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
  sensitive   = true
}

variable "oci_compartment_ocid" {
  description = "OCI compartment OCID where resources will be created"
  type        = string
  sensitive   = true
}

variable "oci_user_ocid" {
  description = "OCI user OCID"
  type        = string
  sensitive   = true
}

variable "oci_fingerprint" {
  description = "OCI API key fingerprint"
  type        = string
  sensitive   = true
}

variable "oci_private_key" {
  description = "OCI API private key content"
  type        = string
  sensitive   = true
}

# ========================================
# Instance Configuration
# ========================================

variable "use_always_free" {
  description = "Use OCI Always Free tier instance (VM.Standard.E2.1.Micro)"
  type        = bool
  default     = true
}

variable "instance_ocpus" {
  description = "Number of OCPUs for flexible shapes (ignored if use_always_free is true)"
  type        = number
  default     = 4
  
  validation {
    condition     = var.instance_ocpus >= 1 && var.instance_ocpus <= 4
    error_message = "Instance OCPUs must be between 1 and 4 for free tier."
  }
}

variable "instance_memory_gb" {
  description = "Memory in GB for flexible shapes (ignored if use_always_free is true)"
  type        = number
  default     = 24
  
  validation {
    condition     = var.instance_memory_gb >= 1 && var.instance_memory_gb <= 24
    error_message = "Instance memory must be between 1 and 24 GB for free tier."
  }
}

variable "boot_volume_size_gb" {
  description = "Boot volume size in GB"
  type        = number
  default     = 50
  
  validation {
    condition     = var.boot_volume_size_gb >= 50 && var.boot_volume_size_gb <= 200
    error_message = "Boot volume size must be between 50 and 200 GB for free tier."
  }
}

variable "enable_preemptible" {
  description = "Enable preemptible instance (can be terminated by OCI)"
  type        = bool
  default     = false
}

# ========================================
# Storage Configuration
# ========================================

variable "create_data_volume" {
  description = "Create a separate data volume for persistent storage"
  type        = bool
  default     = true
}

variable "data_volume_size_gb" {
  description = "Data volume size in GB (for workspace persistence)"
  type        = number
  default     = 100
  
  validation {
    condition     = var.data_volume_size_gb >= 50 && var.data_volume_size_gb <= 200
    error_message = "Data volume size must be between 50 and 200 GB for free tier."
  }
}

variable "enable_backups" {
  description = "Enable automatic backups for data volume"
  type        = bool
  default     = true
}

variable "backup_policy_id" {
  description = "OCI backup policy OCID (use default if not specified)"
  type        = string
  default     = "ocid1.volumebackuppolicy.oc1..aaaaaaaafrt3aaabbc3d3iqvjmj4ggcjltqcaykdcvayocpwbgmqlr6fndqvaq"  # Bronze policy
}

# ========================================
# Network & Security Configuration
# ========================================

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed for SSH access"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_public_key" {
  description = "SSH public key for instance access (leave empty to auto-generate)"
  type        = string
  default     = ""
}

variable "save_ssh_key" {
  description = "Save generated SSH keys to local files"
  type        = bool
  default     = true
}

# ========================================
# Code-Server Configuration
# ========================================

variable "codeserver_version" {
  description = "Code-server version to install"
  type        = string
  default     = "4.20.0"
}

variable "codeserver_user" {
  description = "Username for code-server"
  type        = string
  default     = "coder"
  
  validation {
    condition     = can(regex("^[a-z0-9_-]+$", var.codeserver_user))
    error_message = "Code-server user must contain only lowercase letters, numbers, underscores, and hyphens."
  }
}

variable "enable_https" {
  description = "Enable HTTPS with Let's Encrypt (ignored if Cloudflare tunnel is enabled)"
  type        = bool
  default     = false
}

# ========================================
# Cloudflare Configuration
# ========================================

variable "enable_cloudflare_tunnel" {
  description = "Enable Cloudflare Tunnel for secure access"
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token with Zone:Read and Tunnel:Edit permissions"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_domain" {
  description = "Domain name managed by Cloudflare"
  type        = string
  default     = "example.com"
}

variable "cloudflare_subdomain" {
  description = "Subdomain for code-server access"
  type        = string
  default     = "ide"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.cloudflare_subdomain))
    error_message = "Subdomain must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "cloudflare_allowed_emails" {
  description = "List of email addresses allowed to access code-server"
  type        = list(string)
  default     = []
  
  validation {
    condition     = alltrue([for email in var.cloudflare_allowed_emails : can(regex("^[\\w.-]+@[\\w.-]+\\.[a-z]{2,}$", email))])
    error_message = "All email addresses must be valid."
  }
}

variable "cloudflare_session_duration" {
  description = "Session duration for Cloudflare Access"
  type        = string
  default     = "24h"
  
  validation {
    condition     = can(regex("^[0-9]+[hm]$", var.cloudflare_session_duration))
    error_message = "Session duration must be in format like '24h' or '30m'."
  }
}