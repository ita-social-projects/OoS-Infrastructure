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



