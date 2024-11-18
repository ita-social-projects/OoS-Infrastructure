# External Secret Operator use this GCP Service Account to authenticate with GCP
resource "kubernetes_secret" "gcpsm" {
  metadata {
    name = "gcpsm-secret"
    labels = { type = "gcpsm" }
  }
  data = {
    secret-access-credentials = base64decode(var.external_secret_sa_key)
  }
}
resource "kubectl_manifest" "gcpsm_secret_store" {
  depends_on = [
    kubernetes_secret.gcpsm,
  ]
  yaml_body = <<-EOF
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: example
spec:
  provider:
      gcpsm:
        auth:
          secretRef:
            secretAccessKeySecretRef:
              name: gcpsm-secret
              key: secret-access-credentials
        projectID: ${var.project}
EOF
}

resource "kubectl_manifest" "iit_secret" {
  depends_on = [
    kubectl_manifest.gcpsm_secret_store,
  ]
  yaml_body = <<-EOF
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: SecretStore
    name: example
  target:
    name: iit-example-secret
    creationPolicy: Owner
  data:
  - secretKey: iit-secret
    remoteRef:
      key: iit-secret
EOF
}