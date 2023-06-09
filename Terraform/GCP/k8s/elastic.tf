resource "kubectl_manifest" "elastic_ssl" {
  yaml_body = <<-EOF
  apiVersion: cert-manager.io/v1
  kind: Certificate
  metadata:
    name: elastic-certificates
    namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
  spec:
    dnsNames:
      - elasticsearch-master
      - elasticsearch-master-0
      - elasticsearch-master.default.svc
      - elasticsearch-master.default.svc.cluster.local
    duration: 2160h0m0s
    issuerRef:
      kind: Issuer
      name: ${kubectl_manifest.oos_issuer.name}
    renewBefore: 168h0m0s
    secretName: elastic-certificates
    keystores:
      pkcs12:
        create: true
        passwordSecretRef: # Password used to encrypt the keystore
          key: password-key
          name: pkcs12-password-secret
  EOF
}

resource "helm_release" "elastic" {
  name          = "elastic"
  chart         = "../../k8s/elastic"
  namespace     = data.kubernetes_namespace.oos.metadata[0].name
  wait          = true
  wait_for_jobs = true
  timeout       = 600
  values = [
    "${file("${path.module}/values/elastic.yaml")}"
  ]

  set {
    name  = "kibana.ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/whitelist-source-range"
    value = join("\\,", var.admin_ips)
  }

  set {
    name  = "elasticsearch.ingress.tls[0].hosts[0]"
    value = var.elastic_hostname
  }

  set {
    name  = "elasticsearch.ingress.hosts[0].host"
    value = var.elastic_hostname
  }

  set {
    name  = "kibana.ingress.tls[0].hosts[0]"
    value = var.kibana_hostname
  }

  set {
    name  = "kibana.ingress.hosts[0].host"
    value = var.kibana_hostname
  }

  set {
    name  = "metricbeat.secrets[0].value.user"
    value = var.mysql_user
  }

  depends_on = [
    kubernetes_secret.elastic_credentials,
    kubectl_manifest.elastic_ssl,
    helm_release.ingress
  ]
}
