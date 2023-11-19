output "root_ca_cert_pem" {
  value = tls_self_signed_cert.root_ca.cert_pem
}

output "intermediate_cert_pem" {
  value = tls_locally_signed_cert.intermediate.cert_pem
}

output "intermediate_private_key_pem" {
  value = tls_private_key.intermediate.private_key_pem
}

output "server_cert_pem" {
  value = tls_locally_signed_cert.server.cert_pem
}

output "server_private_key_pem" {
  value = tls_private_key.server.private_key_pem
}

output "client_private_key_pem" {
  value = tls_private_key.client.private_key_pem
}

output "client_cert_pem" {
  value = tls_locally_signed_cert.client.cert_pem
}

output "admin_cert_pem" {
  value = tls_locally_signed_cert.admin.cert_pem
}

output "admin_private_key_pem" {
  value = tls_private_key.admin.private_key_pem
}

output "cluster_ca_certificate" {
  value = format("%s%s%s",
    tls_locally_signed_cert.server.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root_ca.cert_pem
  )
}

output "client_certificate" {
  value = format("%s%s%s%s",
    tls_locally_signed_cert.admin.cert_pem,
    tls_locally_signed_cert.client.cert_pem,
    tls_locally_signed_cert.intermediate.cert_pem,
    tls_self_signed_cert.root_ca.cert_pem
  )
}

output "client_key" {
  value = tls_private_key.admin.private_key_pem
}

output "secret_data" {
  value = google_secret_manager_secret_version.kube_secret.secret_data
}
