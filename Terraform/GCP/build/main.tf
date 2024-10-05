resource "google_pubsub_topic" "cloud_build" {
  name = "cloud-builds"
}

resource "google_pubsub_topic" "gcr" {
  name = "gcr"
}

resource "google_cloudbuild_trigger" "backend_api" {
  provider = google-beta
  location = var.region
  name     = "backend-api"
  repository_event_config {
    repository = google_cloudbuildv2_repository.backend.id
    push {
      branch = "develop"
    }
  }
  substitutions = {
    _GITHUB_DEPLOY = var.github_back_secret
    _REGION        = var.region
  }

  filename        = "cloudbuild-app.yml"
  service_account = var.build_sa_id
}

resource "google_cloudbuild_trigger" "app_deploy" {
  location = var.region
  name     = "backend-api-deploy"
  pubsub_config {
    topic = google_pubsub_topic.gcr.id
  }

  substitutions = {
    _KUBE_CONFIG  = var.kube_secret
    _POOL         = google_cloudbuild_worker_pool.pool.id
    _ACTION       = "$(body.message.data.action)"
    _IMAGE_TAG    = "$(body.message.data.tag)"
    _HOST         = var.app_hostname
    _STAGING_HOST = var.staging_domain
    _SERVICE_NAME = "webapi"
    _REGION       = var.region
    _VALUES_PATH  = "./k8s/infrastructure/webapi.yaml"
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
  filter          = "_ACTION.matches(\"INSERT\") && _IMAGE_TAG.matches(\"^.*oos-api:.*$\")"
  service_account = var.build_sa_id
}

resource "google_cloudbuild_trigger" "backend_auth" {
  provider = google-beta
  location = var.region
  name     = "backend-auth"
  repository_event_config {
    repository = google_cloudbuildv2_repository.backend.id
    push {
      branch = "develop"
    }
  }

  substitutions = {
    _REGION = var.region
  }

  filename        = "cloudbuild-auth.yml"
  service_account = var.build_sa_id
}

resource "google_cloudbuild_trigger" "auth_deploy" {
  location = var.region
  name     = "backend-auth-deploy"
  pubsub_config {
    topic = google_pubsub_topic.gcr.id
  }

  substitutions = {
    _KUBE_CONFIG  = var.kube_secret
    _POOL         = google_cloudbuild_worker_pool.pool.id
    _ACTION       = "$(body.message.data.action)"
    _IMAGE_TAG    = "$(body.message.data.tag)"
    _HOST         = var.auth_hostname
    _STAGING_HOST = var.staging_domain
    _SERVICE_NAME = "authserver"
  }

  source_to_build {
    uri       = "https://github.com/ita-social-projects/OoS-Infrastructure"
    ref       = "refs/heads/main"
    repo_type = "GITHUB"
  }

  git_file_source {
    path      = "cloudbuild-auth-deploy.yaml"
    uri       = "https://github.com/ita-social-projects/OoS-Infrastructure"
    revision  = "refs/heads/main"
    repo_type = "GITHUB"
  }
  filter          = "_ACTION.matches(\"INSERT\") && _IMAGE_TAG.matches(\"^.*oos-auth:.*$\")"
  service_account = var.build_sa_id
}
