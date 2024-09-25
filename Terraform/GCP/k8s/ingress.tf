resource "helm_release" "ingress" {
  name             = "ingress"
  chart            = "../../k8s/infrastructure/charts/ingress-nginx-4.10.0.tgz"
  namespace        = kubernetes_namespace.ingress_nginx.metadata[0].name
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  max_history      = 3
  values = [
    "${file("${path.module}/values/ingress.yaml")}"
  ]

  set {
    name  = "controller.service.enableHttp"
    value = var.enable_ingress_http
  }
  set {
    name  = "controller.service.loadBalancerIP"
    value = var.ingress_ip
  }

  depends_on = [
    helm_release.cert_manager,
    kubectl_manifest.custom_tracing_headers
  ]
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    annotations = {
      name = "ingress-nginx"
    }
    name = "ingress-nginx"
  }
}


# Nginx expects `X-Request-Id` header for request tracing that is exposed as `$req_id` variable.
# .Net Core Serilog ECS Enricher expects `Request-Id` header for this purpose.
resource "kubectl_manifest" "custom_tracing_headers" {
  yaml_body = <<-EOF
apiVersion: v1
data:
  Request-Id: $req_id
kind: ConfigMap
metadata:
  name: custom-headers
  namespace: ${kubernetes_namespace.ingress_nginx.metadata[0].name}
EOF

  ignore_fields = [
    "status",
    "metadata.annotations"
  ]
}

resource "kubectl_manifest" "ingress_elastic" {
  yaml_body = <<-EOF
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: elasticsearch-master
    namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
    labels:
      app: elasticsearch
    annotations:
      cert-manager.io/issuer: "letsencrypt"
      cert-manager.io/duration: 2160h0m0s
      cert-manager.io/renew-before: 168h0m0s
      nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
      nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",", local.whitelist_ips)}
  spec:
    ingressClassName: nginx
    tls:
      - hosts:
          - ${var.elastic_hostname}
        secretName: elastic-tls
    rules:
      - host: ${var.elastic_hostname}
        http:
          paths:
            - path: /
              pathType: ImplementationSpecific
              backend:
                service:
                  name: elasticsearch-es-http
                  port:
                    number: 9200
  EOF
  depends_on = [
    helm_release.ingress
  ]
}

resource "kubectl_manifest" "ingress_kibana" {
  yaml_body = <<-EOF
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: elastic-kibana
    namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
    labels:
      app: kibana
    annotations:
      cert-manager.io/issuer: "letsencrypt"
      cert-manager.io/duration: 2160h0m0s
      cert-manager.io/renew-before: 168h0m0s
      nginx.ingress.kubernetes.io/backend-protocol: HTTPS
      nginx.ingress.kubernetes.io/auth-response-headers: Authorization
      nginx.ingress.kubernetes.io/auth-signin: https://${var.sso_hostname}/oauth2/sign_in?rd=https%3A%2F%2F$http_host$escaped_request_uri
      nginx.ingress.kubernetes.io/auth-url: https://${var.sso_hostname}/oauth2/auth
  spec:
    ingressClassName: nginx
    tls:
      - hosts:
          - ${var.kibana_hostname}
        secretName: kibana-tls
    rules:
      - host: ${var.kibana_hostname}
        http:
          paths:
            - path: /
              pathType: ImplementationSpecific
              backend:
                service:
                  name: kibana-kb-http
                  port:
                    number: 5601
  EOF
  depends_on = [
    helm_release.ingress
  ]
}

# Healthceck does not need auth but needs whitelist
resource "kubectl_manifest" "ingress_kibana_health" {
  yaml_body = <<-EOF
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: elastic-kibana-health
    namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
    labels:
      app: kibana
    annotations:
      nginx.ingress.kubernetes.io/backend-protocol: HTTPS
      nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",", local.whitelist_ips)}
  spec:
    ingressClassName: nginx
    tls:
      - hosts:
          - ${var.kibana_hostname}
        secretName: kibana-tls
    rules:
      - host: ${var.kibana_hostname}
        http:
          paths:
            - path: /api/task_manager/_health
              pathType: ImplementationSpecific
              backend:
                service:
                  name: kibana-kb-http
                  port:
                    number: 5601
  EOF
  depends_on = [
    helm_release.ingress,
    kubectl_manifest.ingress_kibana
  ]
}
