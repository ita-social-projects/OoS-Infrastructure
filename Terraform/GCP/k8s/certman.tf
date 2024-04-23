resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  chart            = "../../k8s/infrastructure/charts/cert-manager-v1.12.3.tgz"
  namespace        = "cert-manager"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  max_history      = 3
  values = [
    "${file("${path.module}/../../../k8s/infrastructure/cert-manager.yaml")}"
  ]
}
