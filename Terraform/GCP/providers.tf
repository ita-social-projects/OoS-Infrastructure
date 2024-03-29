terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    google = {
      version = "~>5.6.0"
    }
    google-beta = {
      version = "~>5.6.0"
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
  host                   = "https://${google_compute_address.lb.address}:${var.k3s_port}"
  cluster_ca_certificate = local.cluster_ca_certificate
  client_certificate     = local.client_certificate
  client_key             = local.client_key
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_compute_address.lb.address}:${var.k3s_port}"
    cluster_ca_certificate = local.cluster_ca_certificate
    client_certificate     = local.client_certificate
    client_key             = local.client_key
  }
}

provider "kubectl" {
  host                   = "https://${google_compute_address.lb.address}:${var.k3s_port}"
  cluster_ca_certificate = local.cluster_ca_certificate
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  load_config_file       = false
}
