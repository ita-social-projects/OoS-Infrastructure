resource "google_secret_manager_secret" "iit_secret" {
  secret_id = "iit-secret"
  labels = { name: "iit-secret" }
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "iit_secret" {
  secret = google_secret_manager_secret.iit_secret.id

  secret_data = "secret-data"
}

