resource "tls_private_key" "root_key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_private_key" "intermediate" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_private_key" "server" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_private_key" "client" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_private_key" "admin" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

###########
# Requests
###########

resource "tls_cert_request" "intermediate" {
  private_key_pem = tls_private_key.intermediate.private_key_pem

  subject {
    common_name         = "k3s-intermediate-ca"
    country             = "UA"
    province            = "Kyiv"
    locality            = "Kyiv"
    organization        = "Software Solutions"
    organizational_unit = "Certification Auhtority"
  }
}

resource "tls_cert_request" "server" {
  private_key_pem = tls_private_key.server.private_key_pem

  subject {
    common_name         = "k3s-server-ca"
    country             = "UA"
    province            = "Kyiv"
    locality            = "Kyiv"
    organization        = "Software Solutions"
    organizational_unit = "Certification Auhtority"
  }
}

resource "tls_cert_request" "client" {
  private_key_pem = tls_private_key.client.private_key_pem

  subject {
    common_name         = "k3s-client-ca"
    country             = "UA"
    province            = "Kyiv"
    locality            = "Kyiv"
    organization        = "Software Solutions"
    organizational_unit = "Certification Auhtority"
  }
}

resource "tls_cert_request" "admin" {
  private_key_pem = tls_private_key.admin.private_key_pem

  subject {
    common_name         = "system:admin"
    country             = "UA"
    province            = "Kyiv"
    locality            = "Kyiv"
    organization        = "system:masters"
    organizational_unit = "Certification Auhtority"
  }
}

######
# PEMs
######

resource "tls_locally_signed_cert" "intermediate" {
  cert_request_pem   = tls_cert_request.intermediate.cert_request_pem
  ca_private_key_pem = tls_private_key.root_key.private_key_pem
  ca_cert_pem        = tls_self_signed_cert.root_ca.cert_pem

  validity_period_hours = 43800 //  1825 days or 5 years

  is_ca_certificate = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "key_encipherment",
    "cert_signing",
  ]
}

resource "tls_locally_signed_cert" "server" {
  cert_request_pem   = tls_cert_request.server.cert_request_pem
  ca_private_key_pem = tls_private_key.intermediate.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.intermediate.cert_pem

  validity_period_hours = 43800 //  1825 days or 5 years

  is_ca_certificate = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "key_encipherment",
    "cert_signing",
  ]
}

resource "tls_locally_signed_cert" "client" {
  cert_request_pem   = tls_cert_request.client.cert_request_pem
  ca_private_key_pem = tls_private_key.intermediate.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.intermediate.cert_pem

  validity_period_hours = 43800 //  1825 days or 5 years

  is_ca_certificate = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "key_encipherment",
    "cert_signing",
  ]
}

resource "tls_locally_signed_cert" "admin" {
  cert_request_pem   = tls_cert_request.admin.cert_request_pem
  ca_private_key_pem = tls_private_key.client.private_key_pem
  ca_cert_pem        = tls_locally_signed_cert.client.cert_pem

  validity_period_hours = 43800 //  1825 days or 5 years

  is_ca_certificate = true

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "key_encipherment",
    "cert_signing",
  ]
}

###########
# Root PEM
###########

resource "tls_self_signed_cert" "root_ca" {
  private_key_pem = tls_private_key.root_key.private_key_pem

  is_ca_certificate = true

  subject {
    common_name         = "k3s-root-ca"
    country             = "UA"
    province            = "Kyiv"
    locality            = "Kyiv"
    organization        = "Software Solutions"
    organizational_unit = "Certification Auhtority"
  }

  validity_period_hours = 43800 //  1825 days or 5 years

  allowed_uses = [
    "digital_signature",
    "cert_signing",
    "key_encipherment",
    "cert_signing",
  ]
}
