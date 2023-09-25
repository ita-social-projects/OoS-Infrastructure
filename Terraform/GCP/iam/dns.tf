resource "google_service_account" "dns" {
  count        = var.enable_dns ? 1 : 0
  account_id   = "cert-dns-${var.random_number}"
  display_name = "Cert Manager Service Account"
}

resource "time_rotating" "dns" {
  count         = var.enable_dns ? 1 : 0
  rotation_days = 30
}

resource "google_service_account_key" "dns" {
  count              = var.enable_dns ? 1 : 0
  service_account_id = google_service_account.dns[0].name

  keepers = {
    rotation_time = time_rotating.dns[0].rotation_rfc3339
  }
}

resource "google_project_iam_custom_role" "dns" {
  count       = var.enable_dns ? 1 : 0
  role_id     = "cloud_dns_zone_cert_manager_custom_role"
  title       = "Cloud DNS Cert Manager"
  description = "A minimal permissions role for DNS challenge"
  permissions = [
    "dns.managedZones.list",
    "dns.resourceRecordSets.create",
    "dns.resourceRecordSets.delete",
    "dns.resourceRecordSets.get",
    "dns.resourceRecordSets.list",
    "dns.resourceRecordSets.update",
    "dns.changes.create",
    "dns.changes.get",
    "dns.changes.list"
  ]
}

resource "google_project_iam_member" "dns" {
  count   = var.enable_dns ? 1 : 0
  role    = google_project_iam_custom_role.dns[0].id
  member  = "serviceAccount:${google_service_account.dns[0].email}"
  project = var.project
}
