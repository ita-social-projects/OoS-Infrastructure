locals {
  kibana_deploy_script_name = "kibana-alerting-rules-script.sh"
  kibana_deploy_tmp         = "scripts/kibana-rules-template.sh"
  kibana_rules_files_list = [
    "fa2a5732-4d98-4b0b-9f0a-1f119a7df4d0", # Node System Load_5m
    "0d857c74-6818-4a18-bf2e-22ca88fa897f", # Elasticsearch Volume Usage
    "1a149616-8628-4c66-8502-334231a7551f", # Kubernetes Pods CPU Usage
    "dbdde86f-f315-4be2-aac0-5650a7804c31", # Kubernetes Pods Memory Usage
    "1b5ec54e-6251-48da-8de0-cd576a5fb285", # Node Disk Usage
    "228b91a2-674f-4450-8e84-ca2044a3c83e", # Node CPU Usage
    "7b58d1e2-6e70-4fdc-95e9-f3e7f03d2a7c", # Node Memory Usage
  ]
  kibana_endpoint = "https://kibana-kb-http:5601"
}

resource "kubernetes_config_map_v1" "kibana_alerting_rule_files" {
  metadata {
    name = "kibana-alert-rules-files"
  }

  data = merge({
    # Kibana rules files
    for name in local.kibana_rules_files_list :
    format("%s.%s",name,"json") => file("${path.module}/config/kibana-rules/${name}.json")
    },
    {
      # bash script
      "${local.kibana_deploy_script_name}" = templatefile("${path.module}/config/${local.kibana_deploy_tmp}", {
        array = local.kibana_rules_files_list
      }),
    }
  )
}

resource "random_id" "suff_kibana_files_list" {
  keepers = {
    # Generate a new suffix for new list
    for k in local.kibana_rules_files_list : k => filemd5("${path.module}/config/kibana-rules/${k}.json")
  }
  byte_length = 4
}

resource "kubectl_manifest" "kibana_rules_job" {
  force_new = true
  yaml_body = <<-EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: deploy-kibana-alert-rules-${lower(random_id.suff_kibana_files_list.hex)}
spec:
  template:
    spec:
      containers:
      - name: curl
        image: ubuntu
        command:
          - /bin/bash
          - -c
          - |
            bash /${local.mount_path}/${local.kibana_deploy_script_name}
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
        - name: KIBANA_ENDPOINT
          value: "${local.kibana_endpoint}"
        - name: ES_PORT
          value: "9200"
        - name: MOUNT_PATH
          value: "${local.mount_path}"
        volumeMounts:
        - name: files
          mountPath: "${local.mount_path}"
      restartPolicy: Never
      volumes:
      - name: files
        configMap:
          name: ${kubernetes_config_map_v1.kibana_alerting_rule_files.metadata[0].name}
  backoffLimit: 4
EOF

  depends_on = [
    helm_release.eck_stack
  ]
}

