resource "google_secret_manager_secret" "geo_key" {
  count     = var.enable_cloud_run ? 1 : 0
  secret_id = "geo-api-key"

  labels = var.labels

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "geo_key" {
  count       = var.enable_cloud_run ? 1 : 0
  secret      = google_secret_manager_secret.geo_key[0].id
  secret_data = var.geo_apikey
}

locals {
  geo_key_list = var.enable_cloud_run ? split("/", google_secret_manager_secret_version.geo_key[0].name) : []
}
