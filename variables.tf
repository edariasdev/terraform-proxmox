variable "pm_api_url" {
  type        = string
  description = "URL for the Proxmox server API; ex: https://proxmox.fqdn:8006/api2/json"
}

variable "pm_password" {
  type        = string
  sensitive   = true
  description = "Password for the pm_user to perform PVE operations;\n Ideally a service account or other 'non-root' user"
}

variable "pm_user" {
  type        = string
  description = "The user name to use for PVE operations;\n Ideally a service account or other 'non-root' user"
}

variable "pve_password" {
  type        = string
  sensitive   = true
  description = "Password for the pve user (within VM/LXC use)"
}

variable "pve_user" {
  type        = string
  description = "The user name for the pve user (within VM/LXC use)"
}

variable "ssh_key" {
  type        = string
  sensitive   = true
  description = "ssh key for VM/LXC user"
}

variable "docker_clone_name" {
  type        = string
  description = "The name of the docker template to clone from."
}

variable "k8s_clone_name" {
  type        = string
  description = "The name of the k8s template to clone from."
}

variable "host_ip" {
  type        = string
  description = "The name ip address of the ProxMox host."
}

variable "nameserver" {
  type        = string
  description = "the ip address of the nameserver to use"
}

variable "num_master_nodes" {
  description = "Number of master nodes for K8s"
  type        = number
  default     = 1
}

variable "num_worker_nodes" {
  description = "Number of worker nodes for K8s"
  type        = number
  default     = 2
}

variable "pm_image_id" {
  type        = string
  description = "The id of the machine image to use for cloning"
}