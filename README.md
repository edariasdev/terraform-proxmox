# Terraform Proxmox K8s Setup

![Screenshot of Proxmox VE logo.](https://www.proxmox.com/images/proxmox/logos/mediakit-proxmox-server-solutions-logos-dark.svg)
![Screenshot of Terraform logo.](https://www.datocms-assets.com/2885/1620155117-brandhcterraformverticalcolorwhite.svg)
![Screenshot of Debian logo.](https://www.debian.org/logos/openlogo.svg)
![Screenshot of Cloudinit logo.](https://cloudinit.readthedocs.io/en/latest/_static/logo.png)

My homelab consists of several Debian-based VMs and LXC/Docker containers running together. <br/>
I've always delayed deployments because provisioning VMs has historically been a lengthy and error-prone task. <br/>
This repo helps me deploy VMs reliably and quickly within Proxox VE environment using Terraform and Cloudinit templates.


## Prerequisites
[Tools required for Proxmox and local host](doc/prerequisites.md)

## What's Installed?
[List of apps and plugins I find useful for VMs](doc/whats+installed.md)

## Troubleshooting
[Issues and fixes to things I've encountered](doc/issues+fixes.md)

# Set up a VM with Terraform
+ https://blog.ayjc.net/posts/terraform/

### cloudinit FAQ:
+ https://pve.proxmox.com/wiki/Cloud-Init_FAQ#Usage_in_Proxmox_VE
+ https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/guides/cloud_init.md

### Meta
+ https://developer.hashicorp.com/terraform/language/meta-arguments/count

### Proxmox Provider:
+ https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/vm_qemu.md
+ https://github.com/Telmate/terraform-provider-proxmox/blob/master/docs/resources/lxc.md
+ https://registry.terraform.io/providers/Telmate/proxmox/2.9.14/docs/resources/lxc

### Other providers:
+ https://registry.terraform.io/browse/providers

### I want to run cloud init commands on my lxc container:
+ https://github.com/terraform-lxd/terraform-provider-lxd/issues/54
+ https://cloudinit.readthedocs.io/en/latest/explanation/format.html
+ https://github.com/hashicorp/terraform-provider-cloudinit/blob/main/docs/resources/config.md
+ https://number1.co.za/managing-lxc-lxd-linux-containers-with-terraform/

### Ansible vs. Terraform Differences:
+ https://www.virtualizationhowto.com/2023/08/ansible-vs-terraform-best-devops-tool/

## AWS Terraform Tutorial:
+ https://medium.com/gruntwork/an-introduction-to-terraform-f17df9c6d180






### Get Debian Cloud Images:
```shell
wget https://cdimage.debian.org/cdimage/cloud/bullseye/latest/debian-11-generic-amd64.qcow2
wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2
```
### Virt-customize and virt-builder:
+ https://www.libguestfs.org/virt-customize.1.html
+ https://www.libguestfs.org/virt-builder.1.html#users-and-passwords
+ https://code.tools/man/1/virt-builder/#lbAN -- This was more helpful than the rest


### Install docker and k8s on ubuntu
+ https://phoenixnap.com/kb/install-kubernetes-on-ubuntu


### cloudinit reference:
+ https://cloudinit.readthedocs.io/en/latest/reference/examples.html#run-apt-or-yum-upgrade

### Helpful K8s Aliases:
+ https://brain2life.hashnode.dev/how-to-set-helpful-aliases-for-kubernetes-commands-in-ubuntu-2004

### To set permanent bash aliases change this file ~/.bash_aliases

```
alias k='kubectl
alias kc='k config view --minify | grep name'
alias kdp='kubectl describe pod'
alias c='clear'
alias kd='kubectl describe pod'
alias ke='kubectl explain'
alias kf='kubectl create -f'
alias kg='kubectl get pods --show-labels'
alias kr='kubectl replace -f'
alias ks='kubectl get namespaces'
alias l='ls -lrt'
alias kga='k get pod --all-namespaces'
alias kgaa='kubectl get all --show-labels'
```

### MD reference:
+ https://docs.github.com/en/get-started/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax
+ https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/creating-and-highlighting-code-blocks
+ https://docs.github.com/en/get-started/writing-on-github/working-with-advanced-formatting/organizing-information-with-tables

### useradd manual:
+ https://manpages.ubuntu.com/manpages/xenial/man8/useradd.8.html



