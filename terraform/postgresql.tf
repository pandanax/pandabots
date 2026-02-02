# Security Group for PostgreSQL
resource "yandex_vpc_security_group" "postgres_sg" {
  name        = "postgres-security-group"
  description = "Security group for PostgreSQL cluster"
  network_id  = yandex_vpc_network.n8n_network.id

  # Доступ из ВМ n8n-server к PostgreSQL
  ingress {
    protocol       = "TCP"
    description    = "PostgreSQL from n8n VM"
    port           = 6432
    v4_cidr_blocks = [yandex_vpc_subnet.n8n_subnet.v4_cidr_blocks[0]]
  }

  # Разрешить весь исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# Managed PostgreSQL Cluster for n8n
resource "yandex_mdb_postgresql_cluster" "n8n_postgres" {
  name        = "n8n-postgres"
  description = "PostgreSQL cluster for n8n workflow automation"
  environment = "PRODUCTION"
  network_id  = yandex_vpc_network.n8n_network.id

  # Привязать security group для доступа
  security_group_ids = [yandex_vpc_security_group.postgres_sg.id]

  config {
    version = "15"
    resources {
      resource_preset_id = "s2.micro" # 2 vCPU, 8 GB RAM
      disk_type_id       = "network-ssd"
      disk_size          = 10 # GB
    }

    postgresql_config = {
      max_connections                 = 100
      shared_buffers                  = 268435456  # 256MB (256 * 1024 * 1024)
      effective_cache_size            = 1073741824 # 1GB (1024 * 1024 * 1024)
      work_mem                        = 2097152    # 2MB (2 * 1024 * 1024)
      maintenance_work_mem            = 67108864   # 64MB (64 * 1024 * 1024)
      max_worker_processes            = 2
      max_parallel_workers_per_gather = 1
      max_parallel_workers            = 2
    }

    backup_window_start {
      hours   = 3
      minutes = 0
    }

    backup_retain_period_days = 7

    access {
      web_sql = true # Доступ через веб-консоль Yandex Cloud
    }
  }

  # Один хост для экономии (без репликации)
  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.n8n_subnet.id
  }

  # Maintenance window (обновления в ночное время)
  maintenance_window {
    type = "WEEKLY"
    day  = "SUN"
    hour = 3
  }

  labels = {
    service = "n8n"
    managed = "terraform"
  }
}

# User for n8n (создаём первым)
resource "yandex_mdb_postgresql_user" "n8n_user" {
  cluster_id = yandex_mdb_postgresql_cluster.n8n_postgres.id
  name       = "n8n"
  password   = var.postgres_password
  conn_limit = 50
}

# Database for n8n (создаём после пользователя)
resource "yandex_mdb_postgresql_database" "n8n_db" {
  cluster_id = yandex_mdb_postgresql_cluster.n8n_postgres.id
  name       = "n8n"
  owner      = yandex_mdb_postgresql_user.n8n_user.name
  lc_collate = "en_US.UTF-8"
  lc_type    = "en_US.UTF-8"

  depends_on = [yandex_mdb_postgresql_user.n8n_user]
}
