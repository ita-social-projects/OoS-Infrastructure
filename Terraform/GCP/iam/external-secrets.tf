resource "google_service_account" "external_secret" {
  account_id   = "external-secrets-sa"
  display_name = "External Secret Operator Account"
}

resource "google_service_account_key" "external_secret_key" {
  service_account_id = google_service_account.external_secret.name
}

resource "google_secret_manager_secret_iam_binding" "iit_secret_accessor" {
  secret_id = var.iit_secret_id
  role = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${google_service_account.external_secret.email}",
  ]
}




