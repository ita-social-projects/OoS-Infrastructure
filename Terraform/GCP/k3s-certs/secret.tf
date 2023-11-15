resource "google_secret_manager_secret" "kube_secret" {
  secret_id = var.k3s_secret

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "kube_secret" {
  secret      = google_secret_manager_secret.kube_secret.id
  secret_data = local.kubeconfig
}