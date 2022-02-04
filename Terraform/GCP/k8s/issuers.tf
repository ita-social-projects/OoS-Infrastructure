resource "kubectl_manifest" "cluster-issuer" {
  depends_on = [
    helm_release.cert-manager,
  ]
  yaml_body = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: ClusterIssuer
  metadata:
    name: selfsigned-issuer
  spec:
    selfSigned: {}
  EOF
}

resource "kubectl_manifest" "ca-certificate" {
  depends_on = [
    helm_release.cert-manager,
  ]
  yaml_body = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    name: selfsigned-ca
    namespace: ${kubernetes_namespace.oos.metadata[0].name}
  spec:
    commonName: selfsigned-ca
    isCA: true
    issuerRef:
      group: cert-manager.io
      kind: ClusterIssuer
      name: ${kubectl_manifest.cluster-issuer.name}
    privateKey:
      algorithm: ECDSA
      size: 256
    secretName: root-secret
  EOF
}

resource "kubectl_manifest" "oos-issuer" {
  depends_on = [
    kubectl_manifest.ca-certificate,
    helm_release.cert-manager
  ]
  yaml_body = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
    name: oos-issuer
    namespace: ${kubernetes_namespace.oos.metadata[0].name}
  spec:
    ca:
      secretName: root-secret
  EOF
}

resource "kubectl_manifest" "letsencrypt-issuer" {
  depends_on = [
    helm_release.cert-manager
  ]
  yaml_body = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
    name: letsencrypt
    namespace: ${kubernetes_namespace.oos.metadata[0].name}
  spec:
    acme:
      email: ${var.letsencrypt_email}
      privateKeySecretRef:
        name: letsencrypt
      server: https://acme-v02.api.letsencrypt.org/directory
      solvers:
        - http01:
            ingress:
              class: nginx
          selector:
            dnsNames:
              - ${var.kibana_hostname}
              - ${var.elastic_hostname}
              - ${var.sql_hostname}
              - ${var.phpmyadmin_hostname}
  EOF
}
