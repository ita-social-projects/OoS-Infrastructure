resource "kubectl_manifest" "mariadb_database" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Database
metadata:
  name: ${var.mariadb_config.database}
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  characterSet: utf8mb4
  collate: utf8mb4_unicode_ci
  cleanupPolicy: Skip
EOF

  depends_on = [
    kubectl_manifest.mariadb_instance
  ]
}

resource "kubectl_manifest" "mariadb_migrations_user" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: User
metadata:
  name: ${var.mariadb_config.users.migrations}
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  passwordSecretKeyRef:
    name: mariadb-credentials
    key: migrationsPassword
  maxUserConnections: 20
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_api_user" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: User
metadata:
  name: ${var.mariadb_config.users.webapi}
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  passwordSecretKeyRef:
    name: mariadb-credentials
    key: apiPassword
  maxUserConnections: 100
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_auth_user" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: User
metadata:
  name: ${var.mariadb_config.users.auth}
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  passwordSecretKeyRef:
    name: mariadb-credentials
    key: authPassword
  maxUserConnections: 100
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_devqc_user" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: User
metadata:
  name: ${var.mariadb_config.users.devqc}
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  passwordSecretKeyRef:
    name: mariadb-credentials
    key: devqcPassword
  maxUserConnections: 20
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_migrations_grant" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: migrations-grant
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  privileges:
    - "ALL PRIVILEGES"
  database: ${var.mariadb_config.database}
  table: "*"
  username: ${var.mariadb_config.users.migrations}
  grantOption: false
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_api_grant" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: webapi-grant
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  privileges:
    - "SELECT"
    - "INSERT"
    - "UPDATE"
    - "DELETE"
  database: ${var.mariadb_config.database}
  table: "*"
  username: ${var.mariadb_config.users.webapi}
  grantOption: false
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_auth_grant" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: auth-grant
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  privileges:
    - "SELECT"
    - "INSERT"
    - "UPDATE"
    - "DELETE"
  database: ${var.mariadb_config.database}
  table: "*"
  username: ${var.mariadb_config.users.auth}
  grantOption: false
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_devqc_grant" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Grant
metadata:
  name: devqc-grant
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  privileges:
    - "SELECT"
  database: ${var.mariadb_config.database}
  table: "*"
  username: ${var.mariadb_config.users.devqc}
  grantOption: false
  host: "%"
  cleanupPolicy: Delete
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_api_connection" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Connection
metadata:
  name: webapi-connection
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  username: ${var.mariadb_config.users.webapi}
  passwordSecretKeyRef:
    name: mariadb-credentials
    key: apiPassword
  database: ${var.mariadb_config.database}
  params:
    parseTime: "true"
  secretName: webapi-mariadb-connection
  secretTemplate:
    metadata:
      labels:
        k8s.mariadb.com/connection: webapi
      annotations:
        k8s.mariadb.com/connection: webapi
    key: dsn
    usernameKey: username
    passwordKey: password
    hostKey: host
    portKey: port
    databaseKey: database
  healthCheck:
    interval: 30s
    retryInterval: 3s
  serviceName: mariadb
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_auth_connection" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Connection
metadata:
  name: auth-connection
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  username: ${var.mariadb_config.users.auth}
  passwordSecretKeyRef:
    name: mariadb-credentials
    key: authPassword
  database: ${var.mariadb_config.database}
  params:
    parseTime: "true"
  secretName: auth-mariadb-connection
  secretTemplate:
    metadata:
      labels:
        k8s.mariadb.com/connection: auth
      annotations:
        k8s.mariadb.com/connection: auth
    key: dsn
    usernameKey: username
    passwordKey: password
    hostKey: host
    portKey: port
    databaseKey: database
  healthCheck:
    interval: 30s
    retryInterval: 3s
  serviceName: mariadb
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}

resource "kubectl_manifest" "mariadb_migrations_connection" {
  yaml_body = <<-EOF
apiVersion: k8s.mariadb.com/v1alpha1
kind: Connection
metadata:
  name: migrations-connection
  namespace: ${data.kubernetes_namespace.oos.metadata[0].name}
spec:
  mariaDbRef:
    name: mariadb
  username: ${var.mariadb_config.users.migrations}
  passwordSecretKeyRef:
    name: mariadb-credentials
    key: migrationsPassword
  database: ${var.mariadb_config.database}
  params:
    parseTime: "true"
  secretName: migrations-mariadb-connection
  secretTemplate:
    metadata:
      labels:
        k8s.mariadb.com/connection: migrations
      annotations:
        k8s.mariadb.com/connection: migrations
    key: dsn
    usernameKey: username
    passwordKey: password
    hostKey: host
    portKey: port
    databaseKey: database
  healthCheck:
    interval: 30s
    retryInterval: 3s
  serviceName: mariadb
EOF

  depends_on = [
    kubectl_manifest.mariadb_database
  ]
}
