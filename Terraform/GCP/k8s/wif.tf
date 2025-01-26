resource "helm_release" "gcp_wif_webhook" {
  name             = "wif-webhook"
  chart            = "../../k8s/infrastructure/charts/gcp-workload-identity-federation-webhook-0.4.6.tgz"
  namespace        = "csi"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  max_history      = 3
}
