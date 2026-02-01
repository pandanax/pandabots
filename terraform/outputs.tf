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
