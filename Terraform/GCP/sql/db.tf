resource "google_sql_database_instance" "storage" {
  name                = "k3s-state-${var.random_number}"
  database_version    = "MYSQL_8_0_26"
  region              = var.region
  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_type         = "PD_HDD"
    disk_autoresize   = true

    ip_configuration {
      ipv4_enabled    = "false"
      private_network = var.network_id
    }

    backup_configuration {
      enabled    = false
      start_time = "01:00"
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

resource "random_id" "storage_password" {
  keepers = {
    name = google_sql_database_instance.storage.name
  }

  byte_length = 8
  depends_on  = [google_sql_database_instance.storage]
}

resource "google_sql_database" "storage" {
  name       = "k3s"
  instance   = google_sql_database_instance.storage.name
  depends_on = [google_sql_database_instance.storage]
}

resource "google_sql_user" "default" {
  name       = "k3s"
  instance   = google_sql_database_instance.storage.name
  password   = random_id.storage_password.hex
  depends_on = [google_sql_database_instance.storage]
}
