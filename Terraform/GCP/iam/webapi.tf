resource "google_service_account" "app" {
  account_id   = "app-run-${var.random_number}"
  display_name = "Application Service Account"
}

resource "google_project_iam_member" "secret-accessor-api" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.app.email}"
  project = var.project
}

resource "google_project_iam_member" "api-log" {
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.app.email}"
  project = var.project
}

resource "time_rotating" "app" {
  rotation_days = 30
}

resource "google_service_account_key" "app" {
  service_account_id = google_service_account.app.name

  keepers = {
    rotation_time = time_rotating.app.rotation_rfc3339
  }
}
