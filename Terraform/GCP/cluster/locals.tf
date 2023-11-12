locals {
  cluster_ca_certificate = base64encode(format("%s%s%s",
    tls_locally_signed_cert.server.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root_ca.cert_pem
  ))

  client_certificate = base64encode(format("%s%s%s%s",
    tls_locally_signed_cert.admin.cert_pem,
    tls_locally_signed_cert.client.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root_ca.cert_pem
  ))

  client_key = base64encode(tls_private_key.admin.private_key_pem)

  kubeconfig-new = <<EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${local.cluster_ca_certificate}
    server: https://${google_compute_address.lb.address}:${var.k3s_port}
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    client-certificate-data: ${local.client_certificate}
    client-key-data: ${local.client_key}
EOT
}
