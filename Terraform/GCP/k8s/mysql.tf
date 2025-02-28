# Replaced by MariaDb CRDs
# Do not delete in case we need it.
# resource "kubectl_manifest" "cm" {
#   yaml_body = file("${path.module}/manifests/cm_initdb.yaml")
# }

# resource "helm_release" "initdb_job" {
#   name          = "mysql-initdb-job"
#   chart         = "../../k8s/job"
#   namespace     = data.kubernetes_namespace.oos.metadata[0].name
#   wait          = true
#   wait_for_jobs = true
#   timeout       = 60
#   max_history   = 3
#   values = [
#     "${file("${path.module}/values/initdb-job.yaml")}"
#   ]
#   depends_on = [
#     resource.kubectl_manifest.cm,
#   ]
# }
resource "kubectl_manifest" "mariadb_monitoring_user" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: User
metadata:
  name: monitoring-user
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  name: ${var.mysql_agent_name}
  mariaDbRef:
    name: mariadb
  passwordSecretKeyRef:
    name: mysql-user-agent
    key: password
  maxUserConnections: 100
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_monitoring_grant_core" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: monitoring-mysql-grant
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  privileges:
    - "CREATE"
    - "INSERT"
  database: mysql
  table: "*"
  username: ${var.mysql_agent_name}
  grantOption: false
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_monitoring_grant_extended" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: monitoring-all-grant
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  privileges:
    - "SELECT"
    - "REPLICATION CLIENT"
    - "SHOW DATABASES"
    - "SUPER"
    - "PROCESS"
    - "EXECUTE"
  database: "*"
  table: "*"
  username: ${var.mysql_agent_name}
  grantOption: false
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}
