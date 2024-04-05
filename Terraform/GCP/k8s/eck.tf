resource "helm_release" "eck_operator" {
  name             = "eck-operator"
  namespace        = "eck-operator"
  chart            = "../../k8s/infrastructure/charts/eck-operator-2.10.0.tgz"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  max_history = 5
  values = [
    "${file("${path.module}/values/operator.yaml")}"
  ]
}

resource "helm_release" "eck_stack" {
  name          = "eck-stack"
  chart         = "../../k8s/infrastructure/eck-stack"
  namespace     = data.kubernetes_namespace.oos.metadata[0].name
  wait          = true
  wait_for_jobs = true
  timeout       = 600
  max_history = 5
  values = [
    "${file("${path.module}/values/eck.yaml")}"
  ]
  set {
    name  = "eck-kibana.spec.config.server.publicBaseUrl"
    value = "https://${var.kibana_hostname}"
  }
  depends_on = [
    helm_release.eck_operator,
    kubectl_manifest.elastic_roles,
    kubernetes_secret.elastic_credentials,
    kubernetes_secret.elastic_webapi_credentials
  ]
}

resource "helm_release" "vector" {
  name             = "vector"
  chart            = "../../k8s/infrastructure/charts/vector-0.29.0.tgz"
  namespace        = data.kubernetes_namespace.oos.metadata[0].name
  wait             = true
  wait_for_jobs    = true
  disable_webhooks = true
  timeout          = 600
  max_history = 5
  values = [
    "${file("${path.module}/values/vector.yaml")}"
  ]
}
resource "kubectl_manifest" "metricbeat_ilm" {
  yaml_body = <<-EOF
apiVersion: v1
kind: Secret
metadata:
  name: metricbeat-ilm-policy
  labels:
    k8s-app: metricbeat
data:
  metricbeat-ilm-policy.json: >-
    ${base64encode(file("${path.module}/config/metricbeat-ilm-policy.json"))}
type: Opaque
EOF
}
