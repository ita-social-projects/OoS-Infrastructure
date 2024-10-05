resource "google_cloudbuild_trigger" "frontend" {
  provider = google-beta
  location = var.region
  name     = "frontend"
  repository_event_config {
    repository = google_cloudbuildv2_repository.frontend.id
    push {
      branch = "develop"
    }
  }

  substitutions = {
    _SERVICE_NAME  = "frontend"
    _STS_SERVER    = "https://${var.staging_domain}/auth"
    _API_SERVER    = "https://${var.staging_domain}/web"
    _GITHUB_DEPLOY = var.github_front_secret
    _REGION        = var.region
  }

  filename        = "cloudbuild.yaml"
  service_account = var.build_sa_id
}

resource "google_cloudbuild_trigger" "frontend_deploy" {
  location = var.region
  name     = "frontend-deploy"
  pubsub_config {
    topic = google_pubsub_topic.gcr.id
  }

  substitutions = {
    _KUBE_CONFIG  = var.kube_secret
    _POOL         = google_cloudbuild_worker_pool.pool.id
    _ACTION       = "$(body.message.data.action)"
    _IMAGE_TAG    = "$(body.message.data.tag)"
    _HOST         = var.front_hostname
    _STAGING_HOST = var.staging_domain
    _VALUES_PATH  = "./k8s/infrastructure/frontend.yaml"
    _SERVICE_NAME = "frontend"
  }

  source_to_build {
    uri       = "https://github.com/ita-social-projects/OoS-Infrastructure"
    ref       = "refs/heads/main"
    repo_type = "GITHUB"
  }

  git_file_source {
    path      = "cloudbuild-deploy.yml"
    uri       = "https://github.com/ita-social-projects/OoS-Infrastructure"
    revision  = "refs/heads/main"
    repo_type = "GITHUB"
  }
  filter          = "_ACTION.matches(\"INSERT\") && _IMAGE_TAG.matches(\"^.*oos-frontend:.*$\")"
  service_account = var.build_sa_id
}
