resource "helm_release" "mysql_operator" {
  name             = "mysql-operator"
  chart            = "../../k8s/infrastructure/charts/mysql-operator-2.1.2.tgz"
  namespace        = "mysql-operator"
  create_namespace = true
  wait             = true
  wait_for_jobs    = true
  max_history      = 3
}

resource "kubernetes_persistent_volume_claim" "backup_pvc" {
  metadata {
    name      = "mysql-backup-pvc"
    namespace = data.kubernetes_namespace.oos.metadata[0].name
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    storage_class_name = "standard"
  }
}

resource "helm_release" "mysql" {
  name          = "mysql"
  chart         = "../../k8s/infrastructure/charts/mysql-innodbcluster-2.1.2.tgz"
  namespace     = data.kubernetes_namespace.oos.metadata[0].name
  wait          = true
  wait_for_jobs = true
  max_history   = 3
  values = [
    "${file("${path.module}/values/mysql.yaml")}"
  ]
  set {
    name  = "credentials.root.password"
    value = var.sql_root_pass
  }
  depends_on = [
    helm_release.mysql_operator,
    helm_release.ingress,
    kubernetes_persistent_volume_claim.backup_pvc
  ]
}

resource "kubectl_manifest" "cm" {
  yaml_body = data.template_file.initdb.rendered
}

data "template_file" "initdb" {
  template = file("${path.module}/manifests/cm_initdb.yaml")

  vars = {
    user_password = random_password.mysql_user_agent.result
  }
}

resource "helm_release" "initdb_job" {
  name          = "mysql-initdb-job"
  chart         = "../../k8s/job"
  namespace     = data.kubernetes_namespace.oos.metadata[0].name
  wait          = true
  wait_for_jobs = true
  timeout       = 60
  max_history   = 3
  values = [
    "${file("${path.module}/values/initdb-job.yaml")}"
  ]
  depends_on = [
    helm_release.mysql_operator,
    resource.helm_release.mysql,
    resource.kubectl_manifest.cm,
  ]
}
