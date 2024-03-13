resource "google_service_account" "build" {
  account_id   = "cloudbuild-sa"
  display_name = "Cloud Build Service Account"
}

resource "google_project_iam_member" "act_as" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.build.email}"
}

resource "google_project_iam_member" "logs_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.build.email}"
}

resource "google_service_account_iam_member" "app_acc_user" {
  service_account_id = google_service_account.app.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.build.email}"
}

resource "google_service_account_iam_member" "auth_acc_user" {
  service_account_id = google_service_account.auth.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.build.email}"
}

resource "google_service_account_iam_member" "front_acc_user" {
  service_account_id = google_service_account.frontend.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.build.email}"
}

resource "google_project_iam_member" "secret_access" {
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.build.email}"
  project = var.project
}

resource "google_project_iam_member" "private_pool" {
  role    = "roles/cloudbuild.workerPoolUser"
  member  = "serviceAccount:${google_service_account.build.email}"
  project = var.project
}

resource "google_project_iam_member" "artifact_registry_push" {
  role    = "roles/artifactregistry.createOnPushWriter"
  member  = "serviceAccount:${google_service_account.build.email}"
  project = var.project
}
