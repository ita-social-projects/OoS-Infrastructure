resource "google_cloudbuild_trigger" "backend_encryption" {
  provider = google-beta
  location = var.region
  name     = "backend-encryption"
  repository_event_config {
    repository = google_cloudbuildv2_repository.backend.id
    push {
      branch = "develop"
    }
  }

  substitutions = {
    _REGION  = var.region
    _IIT_URL = var.iit_libraries_url
  }

  filename        = "cloudbuild-enc.yml"
  service_account = var.build_sa_id
}
