# DNS зона для mandala-app.online
resource "yandex_dns_zone" "mandala_app_online" {
  name        = "mandala-app-online"
  description = "Public DNS zone for mandala-app.online"
  zone        = "mandala-app.online."
  public      = true

  labels = {
    service = "n8n"
    managed = "terraform"
  }
}

# A-запись для n8n.mandala-app.online
resource "yandex_dns_recordset" "n8n_a_record" {
  zone_id = yandex_dns_zone.mandala_app_online.id
  name    = "n8n.mandala-app.online."
  type    = "A"
  ttl     = 300

  data = [yandex_vpc_address.n8n_external_ip.external_ipv4_address[0].address]
}

output "dns_zone_id" {
  description = "DNS Zone ID"
  value       = yandex_dns_zone.mandala_app_online.id
}

output "dns_zone_name" {
  description = "DNS Zone name"
  value       = yandex_dns_zone.mandala_app_online.zone
}

output "n8n_url" {
  description = "n8n URL"
  value       = "https://${trimsuffix(yandex_dns_recordset.n8n_a_record.name, ".")}"
}
