# This is to launch an LXC container for testing purposes. 
terraform {
  backend "s3" {
    bucket         = "edsbucket1"
    key            = "terraform/terraform.lxc.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }

  required_providers {
    proxmox = {
      # https://registry.terraform.io/providers/Telmate/proxmox/latest
      source = "Telmate/proxmox"
      version = "2.9.14"
    }
      # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
    aws = {
      source = "hashicorp/aws"
      version = "4.7.0"
    }
  }
}
provider "proxmox" {
  # https://registry.terraform.io/providers/Telmate/proxmox/latest/docs#argument-reference
  # pm_api_url (Required; or use environment variable PM_API_URL) This is the target Proxmox API endpoint.
  pm_api_url = var.pm_api_url
  pm_tls_insecure = true
  pm_password = var.pm_password
  pm_user = var.pm_user
  pm_otp = ""
  # Adding Logging
  pm_debug = true
  pm_log_enable = true
  pm_log_file   = "log/terraform-k8s-proxmox.log"
  pm_log_levels = {
    _default = "info"
    _capturelog = ""
  }
}


resource "proxmox_lxc" "basic" {
  target_node  = "hera" # name of the PVE node being used
  hostname     = "lxc-basic" # name of the container to use
  ostemplate   = "local:vztmpl/alpine-3.18-default_20230607_amd64.tar.xz" # you need to manually install/DL a LXC/CT image
  password     = "BasicLXCContainer"
  unprivileged = true
  description = "My lxc template using Terraform"
  memory = 250
  nameserver = "192.168.14.1"
  onboot = true
  ssh_public_keys = <<EOF
  ${var.ssh_key}
  EOF
  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-lvm"
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
  }

  lifecycle {
      ignore_changes = [
          network,
        ]
    }

}