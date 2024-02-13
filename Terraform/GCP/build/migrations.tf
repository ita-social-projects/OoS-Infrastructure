resource "google_cloudbuild_trigger" "migrations" {
  provider = google-beta
  location = var.region
  name     = "migrations-bundle"
  repository_event_config {
    repository = google_cloudbuildv2_repository.backend.id
    push {
      branch = "develop"
    }
  }
  substitutions = {
    _REGION = var.region
  }

  filename        = "cloudbuild-migration.yml"
  service_account = var.build_sa_id
}
