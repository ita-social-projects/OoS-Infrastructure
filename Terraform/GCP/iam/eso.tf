resource "google_service_account" "eso" {
  account_id   = "external-secrets-sa"
  display_name = "External Secret Operator Account"
}

resource "google_service_account_key" "eso_key" {
  service_account_id = google_service_account.eso.name
}





