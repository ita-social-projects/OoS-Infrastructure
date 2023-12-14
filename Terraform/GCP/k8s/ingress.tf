resource "helm_release" "ingress" {
  name             = "ingress"
  chart            = "../../k8s/infrastructure/charts/ingress-nginx-4.7.1.tgz"
  namespace        = "ingress-nginx"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  values = [
    "${file("${path.module}/values/ingress.yaml")}"
  ]
  set {
    name  = "tcp.${var.sql_port}"
    value = "default/mysql:3306"
  }
  set {
    name  = "tcp.${var.redis_port}"
    value = "default/redis-master:6379"
  }
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

resource "kubernetes_namespace" "ingress-nginx" {
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
  namespace: ingress-nginx
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
      nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",", var.admin_ips)}
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
      nginx.ingress.kubernetes.io/whitelist-source-range: ${join(",", var.admin_ips)}
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
