resource "google_sql_database_instance" "state" {
  name                = "k3s-state-psql-${var.random_number}"
  database_version    = "POSTGRES_15"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_HDD"
    disk_autoresize   = true
    edition           = "ENTERPRISE"

    database_flags {
      name  = "max_connections"
      value = "100"
    }

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = var.network_id
    }

    backup_configuration {
      enabled    = true
      start_time = "03:00"
      location   = var.region

      backup_retention_settings {
        retained_backups = 7
        retention_unit   = "COUNT"
      }
    }

    maintenance_window {
      day  = 6
      hour = 1
    }

    location_preference {
      zone = var.zone
    }
  }
}

resource "random_id" "state_password" {
  keepers = {
    name = google_sql_database_instance.state.name
  }

  byte_length = 8
  depends_on  = [google_sql_database_instance.state]
}

resource "google_sql_database" "state" {
  name       = "k3s"
  instance   = google_sql_database_instance.state.name
  depends_on = [google_sql_database_instance.state]
}

resource "google_sql_user" "state" {
  name       = "k3s"
  instance   = google_sql_database_instance.state.name
  password   = random_id.state_password.hex
  depends_on = [google_sql_database_instance.state]
}
