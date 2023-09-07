resource "helm_release" "ingress" {
  name             = "ingress"
  chart            = "../../k8s/infrastructure/charts/ingress-nginx-4.7.1.tgz"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  values = [
    "${file("${path.module}/values/ingress.yaml")}"
  ]
  set {
    name  = "tcp.${var.sql_port}"
    value = "default/mysql:3306"
  }
  set {
    name  = "tcp.${var.redis_port}"
    value = "default/redis-master:6379"
  }
  set {
    name  = "controller.service.enableHttp"
    value = var.enable_ingress_http
  }
  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.custom_tracing_headers
  ]
}

# Nginx expects `X-Request-Id` header for request tracing that is exposed as `$req_id` variable.
# .Net Core Serilog ECS Enricher expects `Request-Id` header for this purpose.
resource "kubectl_manifest" "custom_tracing_headers" {
  yaml_body = <<-EOF
apiVersion: v1
data:
  Request-Id: $req_id
kind: ConfigMap
metadata:
  name: custom-headers
  namespace: ingress-nginx
EOF

  ignore_fields = [
    "status",
    "metadata.annotations"
  ]
}
