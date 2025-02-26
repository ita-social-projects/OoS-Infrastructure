resource "helm_release" "mariadb_operator_crds" {
  name             = "mariadb-operator-crds"
  chart            = "../../k8s/infrastructure/charts/mariadb-operator-crds-0.37.1.tgz"
  namespace        = "mariadb-operator"
  create_namespace = true
  wait             = true
  max_history      = 3
}

resource "helm_release" "mariadb_operator" {
  name             = "mariadb-operator"
  chart            = "../../k8s/infrastructure/charts/mariadb-operator-0.37.1.tgz"
  namespace        = "mariadb-operator"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  max_history      = 3
  values = [
    "${file("${path.module}/values/mariadb-operator.yaml")}"
  ]

  depends_on = [
    helm_release.mariadb_operator_crds
  ]
}

resource "kubectl_manifest" "mariadb_config" {
  yaml_body = <<-EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: mariadb-cm
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
  labels:
    k8s.mariadb.com/watch: ""
data:
  my.cnf: |
    [mariadb]
    bind-address=*
    default_storage_engine=InnoDB
    binlog_format=row
    innodb_autoinc_lock_mode=2
    innodb_buffer_pool_size=512M
    innodb_buffer_pool_instances=1
    innodb_log_file_size=50M
    max_connections=150
    innodb_log_buffer_size=64M
    max_allowed_packet=256M
EOF
}

resource "kubectl_manifest" "mariadb_instance" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: MariaDB
metadata:
  name: mariadb
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  replicas: 1

  rootPasswordSecretKeyRef:
    name: mariadb-credentials
    key: rootPassword
    generate: false

  image: docker-registry1.mariadb.com/library/mariadb:${var.mariadb_config.version}

  port: 3306

  storage:
    size: 10Gi
    storageClassName: standard
    resizeInUseVolumes: true
    waitForVolumeResize: true

  myCnfConfigMapKeyRef:
    name: mariadb-cm
    key: my.cnf

  timeZone: "Europe/Kyiv"

  resources:
    requests:
      # cpu: 100m
      memory: 128Mi
    limits:
      memory: 1Gi
  securityContext:
    allowPrivilegeEscalation: false

  tls:
    enabled: true
    enforced: false
    serverCertIssuerRef:
      name: root-ca
      kind: Issuer
    clientCertIssuerRef:
      name: root-ca
      kind: Issuer

  metrics:
    enabled: false
  suspend: false
EOF

  depends_on = [
    helm_release.mariadb_operator,
    kubectl_manifest.mariadb_config
  ]
}
