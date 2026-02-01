# Security Group
resource "yandex_vpc_security_group" "n8n_sg" {
  name        = "n8n-security-group"
  description = "Security group for n8n server"
  network_id  = yandex_vpc_network.n8n_network.id

  # SSH access (only from your IP)
  ingress {
    protocol       = "TCP"
    description    = "SSH access"
    v4_cidr_blocks = [var.allowed_ssh_ip]
    port           = 22
  }

  # HTTP (for Let's Encrypt)
  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  # HTTPS
  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  # Allow all outgoing traffic
  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}
