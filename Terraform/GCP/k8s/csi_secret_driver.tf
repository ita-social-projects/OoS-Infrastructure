resource "helm_release" "secrets_store_csi_driver" {
  name             = "csi-secrets-store"
  chart            = "../../k8s/infrastructure/charts/secrets-store-csi-driver-1.4.8.tgz"
  create_namespace = true
  namespace        = "csi"
  wait             = true
  wait_for_jobs    = true
  max_history      = 5
}

resource "helm_release" "secret_store_csi_prv_gcp" {
  name             = "secret-store-csi-driver-provider-gcp"
  chart            = "../../k8s/infrastructure/charts/secrets-store-csi-driver-provider-gcp-1.7.0.tgz"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true

  values = [
    templatefile("${path.module}/values/secret-csi-prv-gcp.yaml",{
      GCP_PROJECT_ID     = var.project,
      GCP_KSA_TOKEN_PATH = var.wif_credentials.gcp_ksa_token_path,
      GSP_KSA_FILE       = var.wif_credentials.gsp_ksa_file,
      GSP_KSA_CONFIGMAP  = var.wif_credentials.cm_name,
    })
  ]
}

resource "kubernetes_config_map" "wif_credentials" {
  metadata {
    name      = var.wif_credentials.cm_name
    namespace = var.wif_credentials.namespace
  }

  data = {
    config =  templatefile("${path.module}/config/wif_k3s/${var.wif_credentials.gsp_ksa_file}", {
      WIF_PROVIDER_NAME     = var.wif_provider_name,
      SECRET_READER_SA      = var.secret_reader_sa_email,
      WIF_K3S_TOKEN_PATH    = var.wif_credentials.gcp_ksa_token_path,
    })
   }
}

resource "kubectl_manifest" "secret_csi" {
  yaml_body = <<-EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: webapi-secrets
  namespace: default
spec:
  provider: gcp
  parameters:
    secrets: |
      - resourceName: "projects/${var.project}/secrets/${var.gcp_secret_i_name}/versions/latest"
        path: "secret_kep.jks"
EOF
}
