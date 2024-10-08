resource "google_cloudbuild_trigger" "backend_auth_old" {
  count    = var.enable_cloud_run ? 1 : 0
  name     = "backend-auth-old"
  disabled = true
  github {
    owner = "ita-social-projects"
    name  = "OoS-Backend"
    push {
      branch = "develop"
    }
  }

  substitutions = {
    _ASPNETCORE_ENVIRONMENT = "Google"
    _REGION                 = var.region
    _SERVICE_ACCOUNT        = var.auth_sa_email
    _DB_PASS                = var.auth_secret
    _SENDGRID_KEY           = var.sendgrid_key_secret
    _SQL_PORT               = 0
    # TODO: If we return to Cloud Run think about a better way to expose SQL
    # _SQL_PORT               = var.sql_port
  }

  filename = "cloudbuild-auth-old.yml"
}

resource "google_cloudbuild_trigger" "backend_api_old" {
  count    = var.enable_cloud_run ? 1 : 0
  name     = "backend-api-old"
  disabled = true
  github {
    owner = "ita-social-projects"
    name  = "OoS-Backend"
    push {
      branch = "develop"
    }
  }
  substitutions = {
    _ASPNETCORE_ENVIRONMENT = "Google"
    _ZONE                   = var.zone
    _REGION                 = var.region
    _SERVICE_ACCOUNT        = var.app_sa_email
    _DB_PASS                = var.api_secret
    _ES_PASSWORD            = var.es_api_pass_secret
    _BUCKET                 = var.bucket
    _REDIS_PASS             = var.redis_secret
    _REDIS_HOST             = ""
    _REDIS_PORT             = 0
    _SQL_PORT               = 0
    # TODO: If we return to Cloud Run think about a better way to expose SQL & Redis
    # _REDIS_HOST             = var.redis_hostname
    # _REDIS_PORT             = var.redis_port
    # _SQL_PORT               = var.sql_port
    _GEO_KEY = var.geo_key_secret
  }

  filename = "cloudbuild-app-old.yml"
}

resource "google_cloudbuild_trigger" "frontend_old" {
  count    = var.enable_cloud_run ? 1 : 0
  name     = "frontend-old"
  disabled = true
  github {
    owner = "ita-social-projects"
    name  = "OoS-Frontend"
    push {
      branch = "develop"
    }
  }

  substitutions = {
    _REGION          = var.region
    _SERVICE_ACCOUNT = var.front_sa_email
    _SERVICE_NAME    = "frontend"
    _STS_SERVER      = "https://${var.auth_hostname}"
    _API_SERVER      = "https://${var.app_hostname}"
    _GITHUB_DEPLOY   = var.github_front_secret
  }

  filename = "cloudbuild-old.yaml"
}
