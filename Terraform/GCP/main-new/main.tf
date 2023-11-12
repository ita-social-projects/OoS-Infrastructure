locals {
  subdomains = {
    k8s        = var.k8s_api_subdomain
    sql        = var.sql_subdomain,
    phpmyadmin = var.phpmyadmin_subdomain
    kibana     = var.kibana_subdomain
    elastic    = var.elastic_subdomain
    redis      = var.redis_subdomain
    auth       = var.auth_subdomain
    app        = var.app_subdomain
    front      = var.front_subdomain
  }

  hostnames = {
    for name, subdomain in local.subdomains : name => subdomain == "" ? var.dns_domain : "${subdomain}.${var.dns_domain}"
  }

  kubeconfig = yamldecode(data.google_secret_manager_secret_version.kubeconfig.secret_data)

  cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
  client_certificate     = base64decode(local.kubeconfig.users.0.user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users.0.user.client-key-data)
}

data "google_secret_manager_secret_version" "kubeconfig" {
  secret = var.k3s_secret
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "6.0.2"
  project = var.project
  name    = "cloud-router"
  network = "default"
  region  = var.region

  nats = [{
    name = "nat-gateway"
    log_config = {
      enable = false
      filter = "ALL"
    }
  }]
}

module "cluster-new" {
  source           = "../cluster-new"
  project          = var.project
  zone             = var.zone
  region           = var.region
  labels           = var.labels
  random_number    = random_integer.ri.result
  sa_email         = "1082325842510-compute@developer.gserviceaccount.com"
  admin_ips        = var.admin_ips
  k8s_api_hostname = local.hostnames["k8s"]
  credentials      = var.credentials
  db_username      = "user"
  db_password      = "password"
  db_host          = "host"
  subnet_cidr      = "10.128.0.0/20"
  subnet_name      = "default"
  network_name     = "default"
  k3s_version      = var.k3s_version
  k3s_workers      = var.k3s_workers
  k3s_masters      = var.k3s_masters
  k3s_secret       = var.k3s_secret
}

resource "kubectl_manifest" "test" {
  yaml_body  = <<-YAML
kind: Namespace
apiVersion: v1
metadata:
  name: test
  labels:
    name: test
YAML
  depends_on = [module.cluster-new]
}

resource "kubectl_manifest" "test1" {
  yaml_body  = <<-YAML
kind: Namespace
apiVersion: v1
metadata:
  name: test1
  labels:
    name: test1
YAML
  depends_on = [module.cluster-new]
}





