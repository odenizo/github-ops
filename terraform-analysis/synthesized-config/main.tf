# Free Tier Code-Server Deployment
# Synthesized from analysis of multiple repositories
# Optimized for OCI Always Free tier with Cloudflare integration

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.0"
    }
  }
}

# Configure providers
provider "oci" {
  region              = var.oci_region
  tenancy_ocid        = var.oci_tenancy_ocid
  user_ocid           = var.oci_user_ocid
  fingerprint         = var.oci_fingerprint
  private_key         = var.oci_private_key
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

# Local variables
locals {
  # Naming convention
  name_prefix = "${var.project_name}-${var.environment}"
  
  # Network configuration
  vcn_cidr = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
  
  # Instance configuration - Always Free tier optimized
  instance_shape = var.use_always_free ? "VM.Standard.E2.1.Micro" : "VM.Standard.A1.Flex"
  instance_ocpus = var.use_always_free ? 1 : var.instance_ocpus
  instance_memory_gb = var.use_always_free ? 1 : var.instance_memory_gb
  
  # Cloudflare configuration
  cf_tunnel_name = "${local.name_prefix}-tunnel"
  cf_domain_name = "${var.cloudflare_subdomain}.${var.cloudflare_domain}"
  
  # Common tags
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Repository  = "github-ops"
  }
}

# Get availability domains
data "oci_identity_availability_domains" "ads" {
  compartment_id = var.oci_compartment_ocid
}

# Get latest Ubuntu ARM64 image
data "oci_core_images" "ubuntu" {
  compartment_id   = var.oci_compartment_ocid
  operating_system = "Canonical Ubuntu"
  
  # Always Free tier uses x86, ARM shapes use aarch64
  filter {
    name   = "display_name"
    values = var.use_always_free ? 
      ["^Canonical-Ubuntu-20.04-2024.*-x86_64$"] : 
      ["^Canonical-Ubuntu-20.04-aarch64-.*$"]
    regex  = true
  }
}

# Create VCN
resource "oci_core_vcn" "main" {
  compartment_id = var.oci_compartment_ocid
  cidr_blocks    = [local.vcn_cidr]
  display_name   = "${local.name_prefix}-vcn"
  dns_label      = replace(var.project_name, "-", "")
  
  freeform_tags = local.common_tags
}

# Create Internet Gateway
resource "oci_core_internet_gateway" "main" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-igw"
  enabled        = true
  
  freeform_tags = local.common_tags
}

# Create route table
resource "oci_core_route_table" "main" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-rt"
  
  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.main.id
  }
  
  freeform_tags = local.common_tags
}

# Create security list
resource "oci_core_security_list" "main" {
  compartment_id = var.oci_compartment_ocid
  vcn_id         = oci_core_vcn.main.id
  display_name   = "${local.name_prefix}-sl"
  
  # Egress rules
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }
  
  # Ingress rules
  ingress_security_rules {
    # SSH access (restrict to your IP)
    protocol = "6" # TCP
    source   = var.ssh_allowed_cidr
    
    tcp_options {
      min = 22
      max = 22
    }
  }
  
  # Conditional ingress for HTTP when not using Cloudflare tunnel
  dynamic "ingress_security_rules" {
    for_each = var.enable_cloudflare_tunnel ? [] : [1]
    content {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      
      tcp_options {
        min = 80
        max = 80
      }
    }
  }
  
  # Conditional ingress for HTTPS when not using Cloudflare tunnel
  dynamic "ingress_security_rules" {
    for_each = var.enable_cloudflare_tunnel ? [] : [1]
    content {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      
      tcp_options {
        min = 443
        max = 443
      }
    }
  }
  
  freeform_tags = local.common_tags
}

# Create subnet
resource "oci_core_subnet" "main" {
  compartment_id      = var.oci_compartment_ocid
  vcn_id              = oci_core_vcn.main.id
  cidr_block          = local.subnet_cidr
  display_name        = "${local.name_prefix}-subnet"
  dns_label           = "main"
  route_table_id      = oci_core_route_table.main.id
  security_list_ids   = [oci_core_security_list.main.id]
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  
  # Public subnet for simplicity, but can be private with Cloudflare tunnel
  prohibit_public_ip_on_vnic = var.enable_cloudflare_tunnel ? true : false
  
  freeform_tags = local.common_tags
}

# Generate SSH key pair if not provided
resource "tls_private_key" "ssh" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Block volume for persistent storage
resource "oci_core_volume" "data" {
  count               = var.create_data_volume ? 1 : 0
  compartment_id      = var.oci_compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${local.name_prefix}-data-volume"
  size_in_gbs         = var.data_volume_size_gb
  
  freeform_tags = local.common_tags
}

# Cloud-init configuration
data "cloudinit_config" "init" {
  gzip          = true
  base64_encode = true
  
  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/templates/cloud-init.yaml", {
      codeserver_version = var.codeserver_version
      codeserver_user    = var.codeserver_user
      cloudflare_tunnel_token = var.enable_cloudflare_tunnel ? cloudflare_tunnel.main[0].tunnel_token : ""
      enable_cloudflare_tunnel = var.enable_cloudflare_tunnel
      enable_https      = var.enable_https && !var.enable_cloudflare_tunnel
      domain_name       = var.enable_cloudflare_tunnel ? local.cf_domain_name : ""
      data_volume_device = var.create_data_volume ? "/dev/oracleoci/oraclevdb" : ""
    })
  }
}

# Create compute instance
resource "oci_core_instance" "main" {
  compartment_id      = var.oci_compartment_ocid
  availability_domain = data.oci_identity_availability_domains.ads.availability_domains[0].name
  display_name        = "${local.name_prefix}-instance"
  shape               = local.instance_shape
  
  # Shape configuration for flexible shapes
  dynamic "shape_config" {
    for_each = local.instance_shape == "VM.Standard.A1.Flex" ? [1] : []
    content {
      ocpus         = local.instance_ocpus
      memory_in_gbs = local.instance_memory_gb
    }
  }
  
  # Network configuration
  create_vnic_details {
    subnet_id        = oci_core_subnet.main.id
    display_name     = "${local.name_prefix}-vnic"
    assign_public_ip = !var.enable_cloudflare_tunnel
    hostname_label   = replace(local.name_prefix, "-", "")
  }
  
  # Boot volume configuration
  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu.images[0].id
    boot_volume_size_in_gbs = var.boot_volume_size_gb
  }
  
  # Metadata
  metadata = {
    ssh_authorized_keys = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.ssh[0].public_key_openssh
    user_data          = data.cloudinit_config.init.rendered
  }
  
  # Preemptible configuration for cost savings
  dynamic "preemptible_instance_config" {
    for_each = var.enable_preemptible ? [1] : []
    content {
      preemption_action {
        type                 = "TERMINATE"
        preserve_boot_volume = false
      }
    }
  }
  
  timeouts {
    create = "60m"
  }
  
  freeform_tags = local.common_tags
}

# Attach data volume
resource "oci_core_volume_attachment" "data" {
  count           = var.create_data_volume ? 1 : 0
  attachment_type = "paravirtualized"
  instance_id     = oci_core_instance.main.id
  volume_id       = oci_core_volume.data[0].id
  display_name    = "${local.name_prefix}-data-attachment"
  
  # Device name for mounting
  device = "/dev/oracleoci/oraclevdb"
}

# Volume backup policy
resource "oci_core_volume_backup_policy_assignment" "data" {
  count     = var.create_data_volume && var.enable_backups ? 1 : 0
  asset_id  = oci_core_volume.data[0].id
  policy_id = var.backup_policy_id
}

# Cloudflare Tunnel configuration
resource "random_id" "tunnel_secret" {
  count       = var.enable_cloudflare_tunnel ? 1 : 0
  byte_length = 35
}

resource "cloudflare_tunnel" "main" {
  count      = var.enable_cloudflare_tunnel ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = local.cf_tunnel_name
  secret     = random_id.tunnel_secret[0].b64_std
}

# Cloudflare DNS record
data "cloudflare_zone" "main" {
  count = var.enable_cloudflare_tunnel ? 1 : 0
  name  = var.cloudflare_domain
}

resource "cloudflare_record" "main" {
  count   = var.enable_cloudflare_tunnel ? 1 : 0
  zone_id = data.cloudflare_zone.main[0].id
  name    = var.cloudflare_subdomain
  value   = "${cloudflare_tunnel.main[0].id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}

# Cloudflare Access Application
resource "cloudflare_access_application" "main" {
  count            = var.enable_cloudflare_tunnel ? 1 : 0
  zone_id          = data.cloudflare_zone.main[0].id
  domain           = local.cf_domain_name
  name             = "${var.project_name} Code Server"
  type             = "self_hosted"
  session_duration = var.cloudflare_session_duration
  
  # VSCode logo
  logo_url = "https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Visual_Studio_Code_1.35_icon.svg/1024px-Visual_Studio_Code_1.35_icon.svg.png"
}

# Cloudflare Access Policy
resource "cloudflare_access_policy" "main" {
  count          = var.enable_cloudflare_tunnel ? 1 : 0
  application_id = cloudflare_access_application.main[0].id
  zone_id        = data.cloudflare_zone.main[0].id
  name           = "Allow authorized users"
  precedence     = 1
  decision       = "allow"
  
  include {
    email = var.cloudflare_allowed_emails
  }
}

# Save SSH private key locally if generated
resource "local_file" "ssh_private_key" {
  count           = var.ssh_public_key == "" && var.save_ssh_key ? 1 : 0
  content         = tls_private_key.ssh[0].private_key_pem
  filename        = "${path.module}/ssh-keys/${local.name_prefix}-private-key.pem"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  count           = var.ssh_public_key == "" && var.save_ssh_key ? 1 : 0
  content         = tls_private_key.ssh[0].public_key_openssh
  filename        = "${path.module}/ssh-keys/${local.name_prefix}-public-key.pub"
  file_permission = "0644"
}