resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.0"

  project_id   = var.project
  network_name = "outofschool-${random_integer.ri.result}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name               = "outofschool"
      subnet_ip                 = "10.132.0.0/20"
      subnet_region             = var.region
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.5
      subnet_flow_logs_metadata = "EXCLUDE_ALL_METADATA"
      subnet_flow_logs_filter   = "false"
    }
  ]

  firewall_rules = [
    {
      name = "fw-outofschool-${random_integer.ri.result}-allow-internal"

      direction = "INGRESS"

      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]

      ranges   = ["10.132.0.0/20"] #10.128.0.0/9
      priority = 65534
    }
  ]
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 2.0.0"
  project = var.project
  name    = "cloud-router-${random_integer.ri.result}"
  network = module.vpc.network_name
  region  = var.region

  nats = [{
    name = "nat-gateway-${random_integer.ri.result}"
    log_config = {
      enable = false
      filter = "ALL"
    }
  }]
}

resource "google_compute_global_address" "private_ip" {
  name          = "sql-private-ip-${random_integer.ri.result}"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.network_id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
  network                 = module.vpc.network_id
}

module "ops" {
  source             = "./ops"
  project            = var.project
  random_number      = random_integer.ri.result
  network_id         = module.vpc.network_id
  notification_email = var.letsencrypt_email
}

module "storage" {
  source        = "./storage"
  random_number = random_integer.ri.result
  region        = var.region
}

module "iam" {
  source             = "./iam"
  random_number      = random_integer.ri.result
  access_group_email = var.access_group_email
  project            = var.project
  bucket             = module.storage.image_bucket
  logs_bucket        = module.storage.logs_bucket
  devops             = var.devops
}

module "passwords" {
  source = "./passwords"
}

module "sql" {
  source        = "./sql"
  zone          = var.zone
  region        = var.region
  random_number = random_integer.ri.result
  network_id    = module.vpc.network_id

  depends_on = [google_service_networking_connection.private_vpc_connection]
}

module "cluster" {
  source           = "./cluster"
  project          = var.project
  zone             = var.zone
  region           = var.region
  labels           = var.labels
  random_number    = random_integer.ri.result
  sa_email         = module.iam.gke_sa_email
  admin_ips        = var.admin_ips
  k8s_api_hostname = var.k8s_api_hostname
  credentials      = var.credentials
  db_username      = module.sql.db_username
  db_password      = module.sql.db_password
  db_host          = module.sql.db_host
  subnet_cidr      = module.vpc.subnets["${var.region}/outofschool"].ip_cidr_range
  network_name     = module.vpc.network_name
  k3s_version      = var.k3s_version
  k3s_workers      = var.k3s_workers
  k3s_masters      = var.k3s_masters
}

resource "time_sleep" "wait_30_seconds" {
  depends_on = [module.cluster]

  destroy_duration = "30s"
}

provider "kubernetes" {
  config_path = "./cluster/kubeconfig.yaml"
}

provider "helm" {
  kubernetes {
    config_path = "./cluster/kubeconfig.yaml"
  }
}

provider "kubectl" {
  config_path = "./cluster/kubeconfig.yaml"
}

module "k8s" {
  source              = "./k8s"
  project             = var.project
  zone                = var.zone
  admin_ips           = var.admin_ips
  sql_root_pass       = module.passwords.sql_root_pass
  sql_api_pass        = module.passwords.sql_api_pass
  sql_auth_pass       = module.passwords.sql_auth_pass
  es_admin_pass       = module.passwords.es_admin_pass
  es_api_pass         = module.passwords.es_api_pass
  redis_pass          = module.passwords.redis_pass
  csi_sa_email        = module.iam.csi_sa_email
  csi_sa_key          = module.iam.csi_sa_key
  letsencrypt_email   = var.letsencrypt_email
  sql_hostname        = var.sql_hostname
  phpmyadmin_hostname = var.phpmyadmin_hostname
  kibana_hostname     = var.kibana_hostname
  elastic_hostname    = var.elastic_hostname
  sql_port            = var.sql_port
  redis_port          = var.redis_port
  enable_ingress_http = var.enable_ingress_http
  pull_sa_key         = module.iam.pull_sa_key
  pull_sa_email       = module.iam.pull_sa_email
  lb_internal_address = module.cluster.lb_internal_address
  front_hostname      = var.front_hostname
  app_hostname        = var.app_hostname
  auth_hostname       = var.auth_hostname
  sendgrid_key        = var.sendgrid_key
  geo_apikey          = var.geo_apikey
  depends_on = [
    time_sleep.wait_30_seconds
  ]
}

module "secrets" {
  source                     = "./secrets"
  sql_api_pass               = module.passwords.sql_api_pass
  sql_auth_pass              = module.passwords.sql_auth_pass
  es_api_pass                = module.passwords.es_api_pass
  redis_pass                 = module.passwords.redis_pass
  labels                     = var.labels
  sql_hostname               = var.sql_hostname
  sendgrid_key               = var.sendgrid_key
  github_front_deploy_base64 = var.github_front_deploy_base64
  github_back_deploy_base64  = var.github_back_deploy_base64
  github_access_token        = var.github_access_token
  geo_apikey                 = var.geo_apikey
  deployer_kubeconfig        = module.k8s.deployer_kubeconfig
  enable_cloud_run           = var.enable_cloud_run
}

module "build" {
  source                       = "./build"
  app_sa_email                 = module.iam.webapi_sa_email
  auth_sa_email                = module.iam.identity_sa_email
  front_sa_email               = module.iam.frontend_sa_email
  project                      = var.project
  zone                         = var.zone
  region                       = var.region
  api_secret                   = module.secrets.sql_api_secret
  auth_secret                  = module.secrets.sql_auth_secret
  es_api_pass_secret           = module.secrets.es_api_secret
  redis_hostname               = var.redis_hostname
  redis_secret                 = module.secrets.redis_secret
  sender_email                 = var.sender_email
  sendgrid_key_secret          = module.secrets.sendgrid_key_secret
  bucket                       = module.storage.image_bucket
  github_front_secret          = module.secrets.github_front_secret
  github_back_secret           = module.secrets.github_back_secret
  github_token_secret          = module.secrets.github_token_secret
  sql_port                     = var.sql_port
  redis_port                   = var.redis_port
  geo_key_secret               = module.secrets.geo_key_secret
  random_number                = random_integer.ri.result
  network_id                   = module.vpc.network_id
  kube_secret                  = module.secrets.kube_secret
  private_ip_range             = "${google_compute_global_address.private_ip.address}/${google_compute_global_address.private_ip.prefix_length}"
  front_hostname               = var.front_hostname
  app_hostname                 = var.app_hostname
  auth_hostname                = var.auth_hostname
  gcf_bucket                   = module.storage.gcf_bucket
  gcf_sa_email                 = module.iam.gcf_sa_email
  discord_notification_webhook = var.discord_notification_webhook
  enable_cloud_run             = var.enable_cloud_run
}

## TODO: For now it will be here so we can easily move back Cloud Run
## TODO: if something goes wrong with cluster
module "extralb" {
  count         = var.enable_cloud_run ? 1 : 0
  source        = "./extralb"
  project       = var.project
  random_number = random_integer.ri.result
  ingress_name  = module.k8s.ingress_name
  mig_url       = module.cluster.mig_url
  network_name  = module.vpc.network_name
  region        = var.region
  cloud_run_lb = {
    enable = true
    # TODO: Move to variables
    services = {
      frontend = {
        domain = var.front_hostname
      }
      apiservice = {
        domain = var.app_hostname
      }
      authservice = {
        domain = var.auth_hostname
      }
    }
    ssl = true
  }
}
