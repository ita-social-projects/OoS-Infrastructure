resource "kubernetes_config_map" "webapi_cm" {
  metadata {
    name      = "webapi-configmap"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    FileStorage__Containers__Images__BucketName = var.storage_provider == "GoogleCloud" ? var.images_bucket : var.s3_bucket
    FileStorage__Provider                       = var.storage_provider
    AikomApiClient__ApiUrl                      = var.aikom_api_url
    AikomApiClient__TokenEndpoint               = var.aikom_token_endpoint
  }
}

resource "kubernetes_config_map" "authserver_cm" {
  metadata {
    name      = "authserver-configmap"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    AikomApiClient__ApiUrl        = var.aikom_api_url
    AikomApiClient__TokenEndpoint = var.aikom_token_endpoint
  }
}
