resource "google_secret_manager_secret" "secret_es_api" {
  count     = var.enable_cloud_run ? 1 : 0
  secret_id = "es-api"

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_es_api" {
  count       = var.enable_cloud_run ? 1 : 0
  secret      = google_secret_manager_secret.secret_es_api[0].id
  secret_data = var.es_api_pass
}

resource "google_secret_manager_secret" "secret_app_pass" {
  count     = var.enable_cloud_run ? 1 : 0
  secret_id = "app-pass"

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_app_pass" {
  count       = var.enable_cloud_run ? 1 : 0
  secret      = google_secret_manager_secret.secret_app_pass[0].id
  secret_data = var.sql_api_pass
}

resource "google_secret_manager_secret" "secret_auth_pass" {
  count     = var.enable_cloud_run ? 1 : 0
  secret_id = "auth-pass"

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_auth_pass" {
  count       = var.enable_cloud_run ? 1 : 0
  secret      = google_secret_manager_secret.secret_auth_pass[0].id
  secret_data = var.sql_auth_pass
}

resource "google_secret_manager_secret" "secret_sendgrid_key" {
  count     = var.enable_cloud_run ? 1 : 0
  secret_id = "sendgrid-key"

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "secret_sendgrid_key" {
  count       = var.enable_cloud_run ? 1 : 0
  secret      = google_secret_manager_secret.secret_sendgrid_key[0].id
  secret_data = var.sendgrid_key
}

resource "google_secret_manager_secret" "redis_secret" {
  count     = var.enable_cloud_run ? 1 : 0
  secret_id = "redis-pass"

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "redis_secret" {
  count       = var.enable_cloud_run ? 1 : 0
  secret      = google_secret_manager_secret.redis_secret[0].id
  secret_data = var.redis_pass
}

resource "google_secret_manager_secret" "kube_secret" {
  secret_id = "kubeconfig"

  labels = var.labels

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "kube_secret" {
  secret      = google_secret_manager_secret.kube_secret.id
  secret_data = var.deployer_kubeconfig
}

locals {
  api_list          = var.enable_cloud_run ? split("/", google_secret_manager_secret_version.secret_app_pass[0].name) : []
  auth_list         = var.enable_cloud_run ? split("/", google_secret_manager_secret_version.secret_auth_pass[0].name) : []
  es_api_list       = var.enable_cloud_run ? split("/", google_secret_manager_secret_version.secret_es_api[0].name) : []
  sendgrid_key_list = var.enable_cloud_run ? split("/", google_secret_manager_secret_version.secret_sendgrid_key[0].name) : []
  redis_list        = var.enable_cloud_run ? split("/", google_secret_manager_secret_version.redis_secret[0].name) : []
}
