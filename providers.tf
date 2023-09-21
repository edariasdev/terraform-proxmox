terraform {
  backend "s3" {
    bucket  = "edsbucket1"
    key     = "terraform/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    proxmox = {
      # https://registry.terraform.io/providers/Telmate/proxmox/latest
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }
    # 
    aws = {
      source  = "hashicorp/aws"
      version = "4.7.0"
    }
  }
}
provider "proxmox" {
  # https://registry.terraform.io/providers/Telmate/proxmox/latest/docs#argument-reference
  # pm_api_url (Required; or use environment variable PM_API_URL) This is the target Proxmox API endpoint.
  pm_api_url      = var.pm_api_url
  pm_tls_insecure = true
  pm_password     = var.pm_password
  pm_user         = var.pm_user
  pm_otp          = ""
  # Adding Logging
  pm_debug      = true
  pm_log_enable = true
  pm_log_file   = "terraform-proxmox.log"
  pm_log_levels = {
    _default    = "info"
    _capturelog = ""
  }
}