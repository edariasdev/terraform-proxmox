terraform {
  backend "s3" {
    bucket  = "edsbucket1"
    key     = "terraform/terraform.k8s.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    proxmox = {
      # https://registry.terraform.io/providers/Telmate/proxmox/latest
      source  = "Telmate/proxmox"
      version = "2.9.14"
    }
    # https://registry.terraform.io/providers/hashicorp/aws/latest/docs
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
  pm_log_file   = "log/terraform-k8s-proxmox.log"
  pm_log_levels = {
    _default    = "info"
    _capturelog = ""
  }
}

# https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/vm_qemu.md


resource "proxmox_vm_qemu" "master_node" {

  for_each = { for idx in range(var.num_master_nodes) : idx => idx }
  name     = "k8s-master-${each.value}"
  #agent = 1
  target_node = "hera"
  vmid        = 0
  desc        = "k8s-master-${each.value}"
  clone       = var.k8s_clone_name
  # cicustom = "user=local:snippets/cloud-config.yaml"
  # Only use ciuser cipassword if not using cicustom
  # ciuser = var.pve_user
  # cipassword = var.pve_password
  full_clone             = true
  os_type                = "cloud-init"
  memory                 = 6144 # 6GB RAM
  cores                  = 2    # 2 CPUs
  sockets                = 1
  cpu                    = "host"
  define_connection_info = true
  sshkeys                = <<EOF
  ${var.ssh_key}
  EOF
  os_network_config      = <<EOF
auto ens18
iface ens18 inet dhcp
EOF
  nameserver             = var.nameserver
  scsihw                 = "virtio-scsi-pci"
  boot                   = "order=ide0;scsi0;net0"
  bootdisk               = "scsi0"
  vga {
    type = "std"
  }
  network {
    bridge    = "vmbr0"
    firewall  = false
    link_down = false
    model     = "virtio"
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [
      network
    ]
  }
}


resource "proxmox_vm_qemu" "worker_node" {

  for_each = { for idx in range(var.num_worker_nodes) : idx => idx }
  name     = "k8s-worker-${each.value}"
  #agent = 1
  target_node = "hera"
  vmid        = 0
  desc        = "k8s-worker-${each.value}"
  clone       = var.k8s_clone_name
  # # cicustom = "user=local:snippets/cloud-config.yaml"
  # # Only use ciuser cipassword if not using cicustom
  # ciuser = var.pve_user ##Override the default cloud-init user for provisioning.
  # cipassword = var.pve_password ##Override the default cloud-init user's password. Sensitive.
  full_clone             = true
  os_type                = "cloud-init"
  memory                 = 2048 # 2GB RAM
  cores                  = 1    # 1 CPU
  sockets                = 1
  cpu                    = "host"
  define_connection_info = true
  sshkeys                = <<EOF
  ${var.ssh_key}
  EOF
  os_network_config      = <<EOF
auto ens18
iface ens18 inet dhcp
EOF
  nameserver             = var.nameserver
  scsihw                 = "virtio-scsi-pci"
  boot                   = "order=ide0;scsi0;net0"
  bootdisk               = "scsi0"
  vga {
    type = "std"
  }
  network {
    bridge    = "vmbr0"
    firewall  = false
    link_down = false
    model     = "virtio"
  }
  #ipconfig0 = "ip=192.168.14.2${each.value}/24,gw=192.168.14.1"
  # https://github.com/Telmate/terraform-provider-proxmox/issues/704
  # disk {
  #   backup  = true
  #   cache   = "none"
  #   file    = "vm-${each.value.vmid}-disk-0"
  #   format  = "raw"
  #   size    = each.value.disk
  #   storage = "local-lvm"
  #   type    = "virtio"
  #   volume  = "local-lvm:vm-${each.value.vmid}-disk-0"
  # }

  # disk {
  #   storage = "local-lvm"
  #   type = "scsi"
  #   size    = "20G"
  #   slot = 2
  # }
  lifecycle {
    ignore_changes = [
      network
    ]
  }
}