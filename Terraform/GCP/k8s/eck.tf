locals {
  es_deploy_script = "load-elastic-deployment.sh"
  es_deploy_template = "deploy-elastic-template.sh"

  es_endpoints_list = [
    "_ingest/pipeline/geoip-nginx",
    "_component_template/vector-geoip-mappings",
    "_ilm/policy/vector-logs-ilm",
    "_component_template/vector-logs-settings",
    "_index_template/vector-logs-template",
  ]

  # Create files list based on local.es_endpoints_list:
  #  - geoip-nginx.json
  #  - vector-geoip-mappings.json
  #  - vector-logs-ilm.json
  #  - vector-logs-settings.json
  #  - vector-logs-template.json
  es_deploy_files = [
    for name in local.es_endpoints_list:  "${basename(name)}.json"
  ]
}

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

resource "kubernetes_config_map_v1" "files" {
  metadata {
    name = "es-deployment-files"
  }

  data = merge({
    # Elasticsearch Deployment json files
    for name in local.es_deploy_files :
      name => file("${path.module}/config/${name}")
  },
  {
    # bash script
    "${local.es_deploy_script}" = templatefile("${path.module}/config/${local.es_deploy_template}",{
      array = local.es_endpoints_list
    }),
  }
)
}

resource "kubectl_manifest" "policy" {
  yaml_body = <<-EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: elastic-policy-test
spec:
  template:
    spec:
      containers:
      - name: curl
        image: gcr.io/gcp-runtimes/ubuntu_20_0_4
        command:
          - /bin/bash
          - -c
          - |
            bash /script/${local.es_deploy_script}
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
        - name: ES_ENDPOINT
          value: "elasticsearch-es-http"
        - name: ES_PORT
          value: "9200"
        volumeMounts:
        - name: files
          mountPath: /script
      restartPolicy: Never
      volumes:
      - name: files
        configMap:
          name: ${kubernetes_config_map_v1.files.metadata[0].name}
  backoffLimit: 4
EOF
}

