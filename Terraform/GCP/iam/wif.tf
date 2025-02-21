# Configure Workload Identity Federation with K3s
data "google_secret_manager_secret_version_access" "k3s_jwks" {
  project = var.project
  secret  = var.google_secret_name_k3s_jwks
}

resource "google_iam_workload_identity_pool" "k3s_pool" {
  project                   = var.project
  workload_identity_pool_id = "k3s-cluster-pool"
  display_name              = "K3s Cluster"
  description               = "Identity pool for k3s"
}

resource "google_iam_workload_identity_pool_provider" "k3s_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.k3s_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "k3s-prvdr"
  display_name                       = "K3s Kubernetes Cluster"
  oidc {
    issuer_uri = var.wif_issuer_uri
    #allowed_audiences = ["sts.googleapis.com"] # It will be used further
    jwks_json = data.google_secret_manager_secret_version_access.k3s_jwks.secret_data
  }
  attribute_mapping = {
    "google.subject"                 = "assertion.sub"
    "attribute.kubernetes_namespace" = "assertion[\"kubernetes.io\"][\"namespace\"]"
    "attribute.service_account_name" = "assertion[\"kubernetes.io\"][\"serviceaccount\"][\"name\"]"
    "attribute.pod"                  = "assertion[\"kubernetes.io\"][\"pod\"][\"name\"]"
  }
  attribute_condition = var.wif_prv_k3s_conditions
}

resource "google_service_account" "secret_reader" {
  account_id   = "secret-reader"
  display_name = "Secret Reader GCP SA"
}

resource "google_secret_manager_secret_iam_binding" "secret_reader" {
  project   = var.project
  secret_id = var.gcp_secret_i_name
  role      = "roles/secretmanager.secretAccessor"
  members = [
    google_service_account.secret_reader.member
  ]
}

resource "google_service_account_iam_member" "wi_secret_reader" {
  service_account_id = google_service_account.secret_reader.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.k3s_pool.name}/*"
}

