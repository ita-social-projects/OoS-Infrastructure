locals {
  ksa_annotations = "serviceAccount.annotations.iam\\.gke\\.io/gcp-service-account=${var.secret_reader_sa_email}"
}
