resource "kubernetes_config_map" "webapi_cm" {
  metadata {
    name      = "webapi-configmap"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }

  data = {
    GoogleCloudPlatform__Storage__OosImages__BucketName = var.images_bucket
  }
}
