variable "service_account_key_file" {
  description = "Path to service account key file"
  type        = string
  default     = "~/.yc/n8n-sa-key.json"
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  default     = "b1gtthlctc244316ambs"
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  default     = "b1gmrr5e6bncvoin732o"
}

variable "zone" {
  description = "Yandex Cloud Zone"
  type        = string
  default     = "ru-central1-b"
}

variable "vm_name" {
  description = "Virtual Machine name"
  type        = string
  default     = "n8n-server"
}

variable "vm_platform" {
  description = "VM platform"
  type        = string
  default     = "standard-v3"
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "vm_memory" {
  description = "Amount of RAM in GB"
  type        = number
  default     = 4
}

variable "vm_disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "vm_disk_type" {
  description = "Boot disk type"
  type        = string
  default     = "network-ssd"
}

variable "vm_image_family" {
  description = "OS image family"
  type        = string
  default     = "ubuntu-2204-lts"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_user" {
  description = "SSH user name"
  type        = string
  default     = "ubuntu"
}

variable "domain_name" {
  description = "Domain name for n8n"
  type        = string
  default     = "n8n.mandala-app.online"
}

variable "allowed_ssh_ip" {
  description = "IP address allowed to connect via SSH (your IP)"
  type        = string
  # Will be set in terraform.tfvars
}
