resource "helm_release" "phpmyadmin" {
  name          = "phpmyadmin"
  chart         = "../../k8s/infrastructure/charts/phpmyadmin-18.1.4.tgz"
  namespace     = data.kubernetes_namespace.oos.metadata[0].name
  wait          = true
  wait_for_jobs = true
  max_history   = 3
  values = [
    "${file("${path.module}/values/phpmyadmin.yaml")}"
  ]
  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-response-headers"
    value = "Authorization"
  }
  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-signin"
    value = "https://${var.sso_hostname}/oauth2/sign_in?rd=https%3A%2F%2F$http_host$escaped_request_uri"
  }
  set {
    name  = "ingress.annotations.nginx\\.ingress\\.kubernetes\\.io/auth-url"
    value = "https://${var.sso_hostname}/oauth2/auth"
  }
  set {
    name  = "ingress.hostname"
    value = var.phpmyadmin_hostname
  }
  depends_on = [
    helm_release.ingress,
    helm_release.mysql
  ]
}
