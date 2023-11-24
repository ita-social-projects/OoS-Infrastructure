resource "kubernetes_secret" "sql_api_credentials" {
  metadata {
    name      = "mysql-api-auth"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    API_PASSWORD      = var.sql_api_pass
    IDENTITY_PASSWORD = var.sql_auth_pass
  }
}

resource "kubernetes_secret" "elastic_credentials" {
  metadata {
    name      = "elasticsearch-credentials"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    username = "elastic"
    password = var.es_admin_pass
    apipass  = var.es_api_pass
  }
}

resource "kubernetes_secret" "redis_credentials" {
  metadata {
    name      = "redis-auth"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    password = var.redis_pass
  }
}

resource "kubernetes_secret" "pull" {
  metadata {
    name = "outofschool-gcp-pull-secrets"
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://europe-west1-docker.pkg.dev" = {
          "username" = "_json_key"
          "password" = trimspace(base64decode(var.pull_sa_key))
          "email"    = var.pull_sa_email
          "auth"     = base64encode(join(":", ["_json_key", base64decode(var.pull_sa_key)]))
        }
      }
    })
  }
}

resource "kubernetes_secret" "authserver_secrets" {
  metadata {
    name      = "authserver-secrets"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    Email__SendGridKey                       = var.sendgrid_key
    AuthorizationServer__IntrospectionSecret = var.openiddict_introspection_key
  }
}

resource "kubernetes_secret" "webapi_secrets" {
  metadata {
    name      = "webapi-secrets"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    GeoCoding__ApiKey                 = var.geo_apikey
    AuthorizationServer__ClientSecret = var.openiddict_introspection_key
  }
}

resource "random_password" "pkcs12-password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "kubernetes_secret" "pkcs12-password-secret" {
  metadata {
    name      = "pkcs12-password-secret"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    password-key = random_password.pkcs12-password.result
  }
}

resource "random_password" "kibana_encription_key" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "kibana_encription_key" {
  metadata {
    name      = "kibana-encription-key"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    ENCRIPTION_KEY = random_password.kibana_encription_key.result
  }
}

resource "kubernetes_secret" "dns_gcp_credentials" {
  count = var.enable_dns ? 1 : 0
  metadata {
    name      = "dns01-solver-keys"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }
  data = {
    "key.json" = base64decode(var.dns_sa_key)
  }
  depends_on = [
    helm_release.cert_manager
  ]
}

