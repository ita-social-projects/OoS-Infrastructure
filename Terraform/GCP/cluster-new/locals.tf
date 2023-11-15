locals {

  kubeconfig = <<EOT
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: ${var.cluster_ca_certificate}
    server: https://${google_compute_address.lb_internal.address}:${var.k3s_port}
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
    client-certificate-data: ${var.client_certificate}
    client-key-data: ${var.client_key}
EOT
}
