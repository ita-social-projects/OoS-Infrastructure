data "google_project" "project" {
}

resource "google_service_account" "notification" {
  account_id   = "discord-notification-${var.random_number}"
  display_name = "Service account for Discord GCF"
}

resource "google_project_iam_member" "pubsub" {
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
  project = var.project
}

resource "google_project_iam_member" "eventarc" {
  for_each = toset(local.discord_sa_roles)
  role     = each.value
  member   = "serviceAccount:${google_service_account.notification.email}"
  project  = var.project
}

resource "google_service_account_key" "notification" {
  service_account_id = google_service_account.notification.name
}

resource "kubernetes_secret_v1" "notification" {
  metadata {
    name = var.discord_notification_secret_name
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.notification.private_key)
  }
}
