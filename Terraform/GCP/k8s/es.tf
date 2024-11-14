resource "kubernetes_secret" "gcpsm" {
  metadata {
    name = "gcpsm-secret"
    namespace = "es"
  }
  data = {
    "credentials.json" = base64decode(google_service_account_key.eso.private_key)
  }
}