# Configure Workload Identity Federation with K3s

resource "google_iam_workload_identity_pool" "k3s_pool" {
  project                   = var.project
  workload_identity_pool_id = "k3s-cluster"
  display_name              = "K3s Cluster"
  description               = "Identity pool for k3s"
}

resource "google_iam_workload_identity_pool_provider" "onprem-cluster" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.k3s_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "k3s-prvdr"
  display_name                       = "K3s Kubernetes Cluster"
  oidc {
    issuer_uri        = var.wif_issuer_uri
    allowed_audiences = ["sts.googleapis.com"]
  }
  attribute_mapping = {
    "google.subject"                 = "assertion.sub"
    "attribute.kubernetes_namespace" = "assertion[\"kubernetes.io\"][\"namespace\"]"
  }
  attribute_condition = "attribute.kubernetes_namespace==\"csi\""
}
