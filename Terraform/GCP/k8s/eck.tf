resource "helm_release" "eck-operator" {
  name          = "eck-operator"
  chart         = "../../k8s/infrastructure/charts/eck-operator-2.10.0.tgz"
  wait          = true
  wait_for_jobs = true
  values = [
    "${file("${path.module}/values/operator.yaml")}"
  ]
}

resource "helm_release" "vector" {
  name          = "vector"
  chart         = "../../k8s/infrastructure/eck-stack"
  wait          = true
  wait_for_jobs = true
  timeout       = 600
  values = [
    "${file("${path.module}/values/vector.yaml")}"
  ]
  depends_on = [helm_release.eck-operator]
}

resource "helm_release" "eck-stack" {
  name             = "eck-stack"
  chart            = "../../k8s/infrastructure/charts/vector-0.29.0.tgz"
  wait             = true
  wait_for_jobs    = true
  disable_webhooks = true
  timeout          = 600
  values = [
    "${file("${path.module}/values/vector.yaml")}"
  ]
}

