resource "kubectl_manifest" "cluster_issuer" {
  depends_on = [
    helm_release.cert_manager,
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

resource "kubectl_manifest" "ca_certificate" {
  depends_on = [
    helm_release.cert_manager,
  ]
  yaml_body = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    name: selfsigned-ca
    namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
  spec:
    commonName: selfsigned-ca
    isCA: true
    issuerRef:
      group: cert-manager.io
      kind: ClusterIssuer
      name: ${kubectl_manifest.cluster_issuer.name}
    privateKey:
      algorithm: ECDSA
      size: 256
    secretName: root-secret
  EOF
}

resource "kubectl_manifest" "oos_issuer" {
  depends_on = [
    kubectl_manifest.ca_certificate,
    helm_release.cert_manager
  ]
  yaml_body = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Issuer
  metadata:
    name: oos-issuer
    namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
  spec:
    ca:
      secretName: root-secret
  EOF
}

resource "kubectl_manifest" "letsencrypt_issuer" {
  depends_on = [
    helm_release.cert_manager
  ]
  yaml_body = <<-EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: letsencrypt
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  acme:
    email: ${var.letsencrypt_email}
    privateKeySecretRef:
      name: letsencrypt
    server: https://acme-v02.api.letsencrypt.org/directory
    solvers:
    %{if var.enable_dns}
    - dns01:
        cloudDNS:
          project: ${var.project}
          serviceAccountSecretRef:
            name: dns01-solver-keys
            key: key.json
      selector:
        dnsNames:
        - ${var.kibana_hostname}
        - ${var.elastic_hostname}
        - ${var.phpmyadmin_hostname}
        - ${var.front_hostname}
        - ${var.app_hostname}
        - ${var.auth_hostname}
        - ${var.sso_hostname}
    %{endif}
    - http01:
        ingress:
          class: nginx
      selector:
        dnsNames:
        - ${var.staging_domain}
        %{if !var.enable_dns}
        - ${var.kibana_hostname}
        - ${var.elastic_hostname}
        - ${var.phpmyadmin_hostname}
        - ${var.front_hostname}
        - ${var.app_hostname}
        - ${var.auth_hostname}
        - ${var.sso_hostname}
        %{endif}
EOF
}

resource "kubectl_manifest" "mariadb_ca_cert" {
  yaml_body = <<-EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: root-ca
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  duration: 52596h # 6 years
  commonName: root-ca
  usages:
  - digital signature
  - key encipherment
  - cert sign
  issuerRef:
    name: selfsigned-issuer
    kind: ClusterIssuer
  isCA: true
  privateKey:
    encoding: PKCS1
    algorithm: ECDSA
    size: 256
  secretTemplate:
    labels:
      k8s.mariadb.com/watch: ""
  secretName: root-ca
  revisionHistoryLimit: 10
EOF

  depends_on = [
    helm_release.cert_manager
  ]
}

resource "kubectl_manifest" "mariadb_root_ca" {
  yaml_body = <<-EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: root-ca
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  ca:
    secretName: root-ca
EOF

  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.mariadb_ca_cert
  ]
}
