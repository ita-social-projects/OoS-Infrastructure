terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "google" {
  project     = var.project
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials)
}

provider "google-beta" {
  project     = var.project
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials)
}

provider "kubernetes" {
  host                   = "https://${module.cluster.lb_inet_address}:${var.k3s_port}"
  cluster_ca_certificate = local.cluster_ca_certificate
  client_certificate     = local.client_certificate
  client_key             = local.client_key
}

provider "helm" {
  kubernetes {
  host                   = "https://${module.cluster.lb_inet_address}:${var.k3s_port}"
  cluster_ca_certificate = local.cluster_ca_certificate
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  }
}

provider "kubectl" {
  host                   = "https://${module.cluster.lb_inet_address}:${var.k3s_port}"
  cluster_ca_certificate = local.cluster_ca_certificate
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  load_config_file       = false
}
