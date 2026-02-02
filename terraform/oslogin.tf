# OS Login Configuration
#
# OS Login enables centralized SSH access management through Yandex Cloud IAM.
# Users and service accounts can connect via `yc compute ssh` without managing SSH keys manually.

# Variables for OS Login users
variable "organization_id" {
  description = "Yandex Cloud Organization ID for OS Login"
  type        = string
  default     = "bpfbiscmjngo5cdheuhg"
}

variable "oslogin_admin_users" {
  description = "List of user IDs for OS Login admin access (with sudo)"
  type        = list(string)
  default     = ["ajejr683b02rpq8g46jk"] # pandanax-ya
}

variable "oslogin_users" {
  description = "List of user IDs for OS Login regular access"
  type        = list(string)
  default     = []
}

variable "oslogin_service_accounts" {
  description = "List of service account IDs for OS Login access"
  type        = list(string)
  default     = ["ajefmtlpibd23o3ckhfl"] # n8n-bot
}

# NOTE: IAM roles for OS Login must be managed manually via YC CLI
# because they require organization-level permissions that service accounts don't have.
#
# To grant OS Login roles manually:
#
# For admin users (with sudo):
#   yc organization-manager organization add-access-binding <org_id> \
#     --role compute.osAdminLogin --subject userAccount:<user_id>
#
# For regular users:
#   yc organization-manager organization add-access-binding <org_id> \
#     --role compute.osLogin --subject userAccount:<user_id>
#
# For service accounts:
#   yc organization-manager organization add-access-binding <org_id> \
#     --role compute.osLogin --subject serviceAccount:<sa_id>
#
# Current configuration (managed manually):
# - compute.osAdminLogin: ajejr683b02rpq8g46jk (pandanax-ya)
# - compute.osLogin: ajefmtlpibd23o3ckhfl (n8n-bot service account)

# Uncomment below if running terraform with organization owner credentials:
#
# resource "yandex_organizationmanager_organization_iam_member" "oslogin_admins" {
#   for_each        = toset(var.oslogin_admin_users)
#   organization_id = var.organization_id
#   role            = "compute.osAdminLogin"
#   member          = "userAccount:${each.value}"
# }
#
# resource "yandex_organizationmanager_organization_iam_member" "oslogin_users" {
#   for_each        = toset(var.oslogin_users)
#   organization_id = var.organization_id
#   role            = "compute.osLogin"
#   member          = "userAccount:${each.value}"
# }
#
# resource "yandex_organizationmanager_organization_iam_member" "oslogin_service_accounts" {
#   for_each        = toset(var.oslogin_service_accounts)
#   organization_id = var.organization_id
#   role            = "compute.osLogin"
#   member          = "serviceAccount:${each.value}"
# }

# Output OS Login status
output "oslogin_enabled" {
  description = "OS Login is enabled on the VM"
  value       = true
}

output "oslogin_admin_users" {
  description = "Users with OS Admin Login access"
  value       = var.oslogin_admin_users
}

output "oslogin_service_accounts" {
  description = "Service accounts with OS Login access"
  value       = var.oslogin_service_accounts
}
