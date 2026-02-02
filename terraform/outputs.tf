output "vm_external_ip" {
  description = "External IP address of the VM"
  value       = yandex_vpc_address.n8n_external_ip.external_ipv4_address[0].address
}

output "vm_internal_ip" {
  description = "Internal IP address of the VM"
  value       = yandex_compute_instance.n8n_vm.network_interface[0].ip_address
}

output "vm_id" {
  description = "VM instance ID"
  value       = yandex_compute_instance.n8n_vm.id
}

output "ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.ssh_user}@${yandex_vpc_address.n8n_external_ip.external_ipv4_address[0].address}"
}

output "dns_record" {
  description = "DNS A record to create"
  value = {
    type  = "A"
    host  = "n8n"
    value = yandex_vpc_address.n8n_external_ip.external_ipv4_address[0].address
    ttl   = 300
  }
}

output "domain_name" {
  description = "Domain name for n8n"
  value       = var.domain_name
}

# PostgreSQL Outputs
output "postgres_cluster_id" {
  description = "PostgreSQL cluster ID"
  value       = yandex_mdb_postgresql_cluster.n8n_postgres.id
}

output "postgres_cluster_name" {
  description = "PostgreSQL cluster name"
  value       = yandex_mdb_postgresql_cluster.n8n_postgres.name
}

output "postgres_host" {
  description = "PostgreSQL host (FQDN)"
  value       = yandex_mdb_postgresql_cluster.n8n_postgres.host[0].fqdn
}

output "postgres_connection_string" {
  description = "PostgreSQL connection string for n8n"
  value       = "postgresql://${yandex_mdb_postgresql_user.n8n_user.name}:${var.postgres_password}@${yandex_mdb_postgresql_cluster.n8n_postgres.host[0].fqdn}:6432/${yandex_mdb_postgresql_database.n8n_db.name}"
  sensitive   = true
}

output "postgres_database_name" {
  description = "PostgreSQL database name"
  value       = yandex_mdb_postgresql_database.n8n_db.name
}

output "postgres_user" {
  description = "PostgreSQL user name"
  value       = yandex_mdb_postgresql_user.n8n_user.name
}

output "postgres_security_group_id" {
  description = "PostgreSQL security group ID"
  value       = yandex_vpc_security_group.postgres_sg.id
}
