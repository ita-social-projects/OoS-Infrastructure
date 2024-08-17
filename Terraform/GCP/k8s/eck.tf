resource "helm_release" "eck_operator" {
  name             = "eck-operator"
  namespace        = "eck-operator"
  chart            = "../../k8s/infrastructure/charts/eck-operator-2.13.0.tgz"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  max_history      = 3
  values = [
    "${file("${path.module}/values/operator.yaml")}"
  ]
}

resource "helm_release" "eck_stack" {
  name          = "eck-stack"
  chart         = "../../k8s/infrastructure/eck-stack"
  namespace     = data.kubernetes_namespace.oos.metadata[0].name
  wait          = true
  wait_for_jobs = true
  timeout       = 600
  max_history   = 3
  values = [
    "${file("${path.module}/values/eck.yaml")}"
  ]
  set {
    name  = "eck-kibana.spec.config.server.publicBaseUrl"
    value = "https://${var.kibana_hostname}"
  }
  depends_on = [
    helm_release.eck_operator,
    kubectl_manifest.elastic_roles,
    kubernetes_secret.elastic_credentials,
    kubernetes_secret.elastic_webapi_credentials,
    resource.helm_release.initdb_job,
  ]
}

resource "helm_release" "vector" {
  name             = "vector"
  chart            = "../../k8s/infrastructure/charts/vector-0.32.1.tgz"
  namespace        = data.kubernetes_namespace.oos.metadata[0].name
  wait             = true
  wait_for_jobs    = true
  disable_webhooks = true
  timeout          = 600
  max_history      = 3
  values = [
    "${file("${path.module}/values/vector.yaml")}"
  ]
}

resource "kubectl_manifest" "metricbeat_ilm" {
  yaml_body = <<-EOF
apiVersion: v1
kind: Secret
metadata:
  name: metricbeat-ilm-policy
  labels:
    k8s-app: metricbeat
data:
  metricbeat-ilm-policy.json: >-
    ${base64encode(file("${path.module}/config/metricbeat-ilm-policy.json"))}
type: Opaque
EOF
}



resource "kubectl_manifest" "policy" {
  for_each = toset(local.list_policy_files)
  yaml_body = <<-EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: elastic-policy-${each.value}
spec:
  template:
    spec:
      containers:
      - name: curl
        image: alpine/curl
        command:
          - sh
          - -c
          - |
            echo ${local.script} | base64 -d > script.sh
            chmod +x script.sh
            sh script.sh
            echo "${each.value}"
        env:
        - name: USERNAME
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: username
        - name: PASSWORD
          valueFrom:
            secretKeyRef:
              name: elastic-credentials
              key: password
      restartPolicy: Never
  backoffLimit: 4
EOF
}

locals {
  script = base64encode(file("k8s/config/load_elastic_policy.sh"))
  list_policy_files = endpoint : [
    "geoip-nginx-pipeline",
    "vector-geoip-mappings",
    "vector-logs-ilm",
    "vector-logs-settings",
    "vector-logs-template",
  ]
}
