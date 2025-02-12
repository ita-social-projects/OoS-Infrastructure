output "webapi_sa_email" {
  value = google_service_account.app.email
}

output "identity_sa_email" {
  value = google_service_account.auth.email
}

output "frontend_sa_email" {
  value = google_service_account.frontend.email
}

output "gke_sa_email" {
  value = google_service_account.gke.email
}

output "csi_sa_email" {
  value = google_service_account.csi.email
}

output "csi_sa_key" {
  value = google_service_account_key.csi.private_key
}

output "pull_sa_email" {
  value = google_service_account.csi.email
}

output "pull_sa_key" {
  value = google_service_account_key.pull.private_key
}

output "gcf_sa_email" {
  value = google_service_account.notification.email
}

output "dns_sa_key" {
  value = var.enable_dns ? google_service_account_key.dns[0].private_key : ""
}

output "build_sa_id" {
  value = google_service_account.build.id
}

output "webapi_sa_key" {
  value = google_service_account_key.app.private_key
}

output "wif_provider_name" {
  value = google_iam_workload_identity_pool_provider.k3s_provider.name
}

output "secret_reader_sa_email" {
  value = google_service_account.secret_reader.email
}
