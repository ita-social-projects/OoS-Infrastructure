resource "google_secret_manager_secret" "eck" {
  secret_id = "remote_monitoring_eck_password"

  labels = {
    app = "eck"
  }

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "eck" {
  secret      = google_secret_manager_secret.eck.id
  secret_data = var.eck_password
}

