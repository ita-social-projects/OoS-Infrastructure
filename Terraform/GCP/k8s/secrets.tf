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

resource "kubectl_manifest" "elastic_roles" {
  yaml_body = <<-EOF
kind: Secret
apiVersion: v1
metadata:
  name: elastic-roles-secret
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
stringData:
  roles.yml: |-
    outofschool:
      cluster:
        - monitor
      indices:
        - names:
            - workshop
          privileges:
            - read
            - write
            - delete
            - create_index
            - view_index_metadata
            - manage
          allow_restricted_indices: false
      metadata:
        version: 2
    devqcaccess:
      cluster:
        - monitor
      indices:
        - names:
            - devqc-*
          privileges:
            - read
            - write
            - delete
            - create_index
            - view_index_metadata
            - manage
          allow_restricted_indices: false
        - names:
            - logs-apm*
            - metrics-apm*
            - traces-apm*
            - workshop
          privileges:
            - read
            - view_index_metadata
          allow_restricted_indices: false
      applications:
        - application: kibana-.kibana
          privileges:
            - space_read
          resources:
            - space:default
      metadata:
        version: 2
EOF
}

resource "kubernetes_secret" "elastic_credentials" {
  metadata {
    name      = "elastic-credentials"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    username = "elastic"
    password = var.es_admin_pass
    roles    = "superuser"
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "elastic_webapi_credentials" {
  metadata {
    name      = "webapi-es-credentials"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    username = "webapi"
    password = var.es_api_pass
    roles    = "outofschool"
  }
  type = "kubernetes.io/basic-auth"
}

resource "kubernetes_secret" "elastic_devqc_credentials" {
  metadata {
    name      = "devqc-es-credentials"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    username = "devqc"
    password = var.es_dev_qc_password
    roles    = "devqcaccess"
  }
  type = "kubernetes.io/basic-auth"
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
    Email__AddressFrom                       = var.sender_email
    AikomApiClient__ClientId                 = var.aikom_client_id
    AikomApiClient__ClientSecret             = var.aikom_client_secret
  }
}

resource "kubernetes_secret" "webapi_secrets" {
  metadata {
    name      = "webapi-secrets"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    Email__SendGridKey                           = var.sendgrid_key
    Email__AddressFrom                           = var.sender_email
    GeoCoding__ApiKey                            = var.geo_apikey
    AuthorizationServer__ClientSecret            = var.openiddict_introspection_key
    FileStorage__Providers__AmazonS3__AccessKey  = var.aws_access_key_id
    FileStorage__Providers__AmazonS3__SecretKey  = var.aws_secret_access_key
    FileStorage__Providers__AmazonS3__ServiceUrl = var.s3_host
    AikomApiClient__ClientId                     = var.aikom_client_id
    AikomApiClient__ClientSecret                 = var.aikom_client_secret
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

resource "kubernetes_secret" "remote_monitoring_user" {
  metadata {
    name      = "elastic-user-rmon"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    username = "remote_monitoring_agent"
    password = var.es_user_rmon_password
    roles    = "remote_monitoring_agent"
  }
  type = "kubernetes.io/basic-auth"
}

resource "random_password" "mysql_user_agent" {
  length  = 32
  special = false
}

resource "kubernetes_secret" "mysql_user_agent" {
  metadata {
    name      = "mysql-user-agent"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }
  data = {
    user     = var.mysql_agent_name
    password = random_password.mysql_user_agent.result
  }
}

resource "kubernetes_secret" "webapi_gcp_credentials" {
  metadata {
    name      = "webapi-gcp-sa"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }
  data = {
    "key.json" = base64decode(var.webapi_sa_key)
  }
}
