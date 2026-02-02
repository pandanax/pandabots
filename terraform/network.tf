# VPC Network
resource "yandex_vpc_network" "n8n_network" {
  name        = "n8n-network"
  description = "Network for n8n project"
}

# Subnet
resource "yandex_vpc_subnet" "n8n_subnet" {
  name           = "n8n-subnet"
  description    = "Subnet for n8n VM"
  zone           = var.zone
  network_id     = yandex_vpc_network.n8n_network.id
  v4_cidr_blocks = ["10.128.0.0/24"]
}

# Static external IP
resource "yandex_vpc_address" "n8n_external_ip" {
  name = "n8n-external-ip"

  external_ipv4_address {
    zone_id = var.zone
  }
}
