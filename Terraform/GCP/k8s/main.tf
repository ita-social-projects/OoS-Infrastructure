terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
    helm = {
      source = "hashicorp/helm"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

data "kubernetes_namespace" "oos" {
  metadata {
    name = "default"
  }
}

resource "kubectl_manifest" "sc" {
  yaml_body = <<-EOF
  allowVolumeExpansion: true
  apiVersion: storage.k8s.io/v1
  kind: StorageClass
  metadata:
    annotations:
      storageclass.kubernetes.io/is-default-class: "true"
    labels:
      addonmanager.kubernetes.io/mode: EnsureExists
    name: standard
  parameters:
    type: pd-standard
  provisioner: pd.csi.storage.gke.io
  volumeBindingMode: Immediate
  EOF
}

# Kubernetes CronJob to sync files from a production MinIO bucket to a GCS bucket in Development.
resource "helm_release" "minio_rsync" {
  name          = "minio-sync-job"
  chart         = "../../k8s/job"
  namespace     = data.kubernetes_namespace.oos.metadata[0].name
  wait          = true
  wait_for_jobs = true
  timeout       = 60
  max_history   = 3
  values = [
    "${file("${path.module}/values/minio-sync.yaml")}"
  ]
}
