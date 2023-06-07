resource "google_service_account" "pull" {
  account_id   = "gcr-puller-${var.random_number}"
  display_name = "Pull from Artifact Registry"
}

resource "google_project_iam_member" "pull" {
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.pull.email}"
  project = var.project
}

resource "time_rotating" "pull_key_rotation" {
  rotation_days = 30
}

resource "google_service_account_key" "pull" {
  service_account_id = google_service_account.pull.name

  keepers = {
    rotation_time = time_rotating.pull_key_rotation.rotation_rfc3339
  }
}
