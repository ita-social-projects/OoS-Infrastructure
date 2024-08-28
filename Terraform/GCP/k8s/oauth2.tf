# As there is no plan to have this in prod - using pure TF config

resource "random_password" "cookie_secret" {
  length           = 32
  override_special = "-_"
}

resource "kubernetes_namespace_v1" "oauth2_proxy" {
  metadata {
    name = "oauth2-proxy"
  }
}

resource "kubernetes_secret_v1" "oauth2_proxy_secret" {
  metadata {
    name      = "oauth2-proxy-secret"
    namespace = kubernetes_namespace_v1.oauth2_proxy.metadata[0].name
  }

  data = {
    client_id      = var.oauth2_github_client_id
    client_secret  = var.oauth2_github_client_secret
    cookie_secret  = random_password.cookie_secret.result
    redis_password = var.redis_pass
  }
}

resource "kubernetes_config_map_v1" "oauth2_proxy_config" {
  metadata {
    name      = "oauth2-proxy-config"
    namespace = kubernetes_namespace_v1.oauth2_proxy.metadata[0].name
  }

  data = {
    "oauth2-proxy.cfg" = <<EOF
provider="github"
# Upstream config
http_address="0.0.0.0:4180"
upstreams="file:///dev/null"
cookie_refresh="1h"
email_domains=["*"]
github_org="${var.oauth2_github_org}"
github_team="${join(",", var.oauth2_github_teams)}"
cookie_domains=[".${var.front_hostname}"]
scope="openid profile user:email read:org"
whitelist_domains=[".${var.front_hostname}:*"]
# Redis session store config
session_store_type="redis"
redis_connection_url="redis://${kubernetes_service_v1.oauth2_proxy_redis.metadata[0].name}:6379"
    EOF
  }
}

resource "kubernetes_service_v1" "oauth2_proxy" {
  metadata {
    name      = "oauth2-proxy"
    namespace = kubernetes_namespace_v1.oauth2_proxy.metadata[0].name
    labels = {
      app = "oauth2-proxy"
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = "oauth2-proxy"
    }
    port {
      port = 4180
      name = "http-oauth2proxy"
    }
  }
}

# Re-using redis becuase we're low on resources :)
resource "kubernetes_service_v1" "oauth2_proxy_redis" {
  metadata {
    name      = "redis"
    namespace = kubernetes_namespace_v1.oauth2_proxy.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = "redis-master.${data.kubernetes_namespace.oos.metadata[0].name}.svc.cluster.local"
  }
}

# Did not plan to have Ingress in other namespaces so we only have a namespace bound Issuer instead of ClusterIssuer.
# To issue Let's Encrypt certificate need to have Ingress in default NS -> need to have a local service.
resource "kubernetes_service_v1" "oauth2_proxy_default" {
  metadata {
    name      = "oauth2-proxy"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }
  spec {
    type          = "ExternalName"
    external_name = "oauth2-proxy.${kubernetes_namespace_v1.oauth2_proxy.metadata[0].name}.svc.cluster.local"
  }
}

resource "kubernetes_ingress_v1" "oauth2_proxy" {
  metadata {
    name      = "oauth2-proxy"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
    annotations = {
      "nginx.ingress.kubernetes.io/proxy-send-timeout" = "300"
      "cert-manager.io/issuer"                         = "letsencrypt"
      "cert-manager.io/duration"                       = "2160h0m0s"
      "cert-manager.io/renew-before"                   = "168h0m0s"
    }
  }

  spec {
    tls {
      secret_name = "${var.sso_hostname}-tls"
      hosts       = [var.sso_hostname]
    }
    ingress_class_name = "nginx"
    rule {
      host = var.sso_hostname
      http {
        path {
          path      = "/oauth2"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.oauth2_proxy_default.metadata[0].name
              port {
                number = kubernetes_service_v1.oauth2_proxy.spec[0].port[0].port
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment_v1" "oauth2_proxy" {
  metadata {
    name      = "oauth2-proxy"
    namespace = kubernetes_namespace_v1.oauth2_proxy.metadata[0].name
    labels = {
      app = "oauth2-proxy"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "oauth2-proxy"
      }
    }
    template {
      metadata {
        labels = {
          app = "oauth2-proxy"
        }
      }
      spec {
        volume {
          name = "oauth2-proxy-config"
          config_map {
            name = kubernetes_config_map_v1.oauth2_proxy_config.metadata[0].name
          }
        }
        container {
          name              = "oauth2-proxy"
          image             = "quay.io/oauth2-proxy/oauth2-proxy:latest"
          image_pull_policy = "Always"
          port {
            container_port = 4180
          }
          volume_mount {
            name       = "oauth2-proxy-config"
            mount_path = "/etc/oauth2-proxy.cfg"
            sub_path   = "oauth2-proxy.cfg"
          }
          args = ["--config=/etc/oauth2-proxy.cfg"]
          resources {
            requests = {
              memory = "10M"
            }
            limits = {
              memory = "50M"
            }
          }
          env {
            name = "OAUTH2_PROXY_REDIS_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.oauth2_proxy_secret.metadata[0].name
                key  = "redis_password"
              }
            }
          }
          env {
            name = "OAUTH2_PROXY_COOKIE_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.oauth2_proxy_secret.metadata[0].name
                key  = "cookie_secret"
              }
            }
          }
          env {
            name = "OAUTH2_PROXY_CLIENT_SECRET"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.oauth2_proxy_secret.metadata[0].name
                key  = "client_secret"
              }
            }
          }
          env {
            name = "OAUTH2_PROXY_CLIENT_ID"
            value_from {
              secret_key_ref {
                name = kubernetes_secret_v1.oauth2_proxy_secret.metadata[0].name
                key  = "client_id"
              }
            }
          }
        }
      }
    }
  }
}
