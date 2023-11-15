resource "google_secret_manager_secret_version" "kube_secret" {
  secret      = "projects/${var.project}/secrets/${var.k3s_secret}"
  secret_data = local.kubeconfig
}