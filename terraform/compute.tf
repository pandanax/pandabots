# Virtual Machine
resource "yandex_compute_instance" "n8n_vm" {
  name        = var.vm_name
  platform_id = var.vm_platform
  zone        = var.zone

  resources {
    cores  = var.vm_cores
    memory = var.vm_memory
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = var.vm_disk_size
      type     = var.vm_disk_type
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.n8n_subnet.id
    nat                = true
    nat_ip_address     = yandex_vpc_address.n8n_external_ip.external_ipv4_address[0].address
    security_group_ids = [yandex_vpc_security_group.n8n_sg.id]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_public_key_path)}"
    user-data = templatefile("${path.module}/cloud-init.yaml", {
      ssh_user       = var.ssh_user
      ssh_public_key = file(var.ssh_public_key_path)
      domain_name    = var.domain_name
    })
  }

  scheduling_policy {
    preemptible = false
  }
}

# Data source for Ubuntu image
data "yandex_compute_image" "ubuntu" {
  family = var.vm_image_family
}
