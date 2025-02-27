locals {
  subdomains = {
    k8s        = var.k8s_api_subdomain
    phpmyadmin = var.phpmyadmin_subdomain
    kibana     = var.kibana_subdomain
    elastic    = var.elastic_subdomain
    auth       = var.auth_subdomain
    app        = var.app_subdomain
    front      = var.front_subdomain
    sso        = var.sso_subdomain
  }

  hostnames = {
    for name, subdomain in local.subdomains : name => subdomain == "" ? var.dns_domain : "${subdomain}.${var.dns_domain}"
  }

  kubeconfig = yamldecode(module.k3s_certs.secret_data)

  cluster_ca_certificate = base64decode(local.kubeconfig.clusters.0.cluster.certificate-authority-data)
  client_certificate     = base64decode(local.kubeconfig.users.0.user.client-certificate-data)
  client_key             = base64decode(local.kubeconfig.users.0.user.client-key-data)
}

resource "random_integer" "ri" {
  min = 10000
  max = 99999
}

module "network" {
  source        = "./network"
  project       = var.project
  region        = var.region
  random_number = random_integer.ri.result
}

module "ops" {
  source                 = "./ops"
  discord_webhook        = var.gcp_monitoring_discord_webhook
  discord_kibana_webhook = var.kibana_alerting_discord_webhook
  eck_rmon_password      = module.passwords.es_user_rmon_password
  gcf_bucket             = module.storage.gcf_bucket
  network_id             = module.network.vpc.network_id
  notification_email     = var.letsencrypt_email
  project                = var.project
  random_number          = random_integer.ri.result
  region                 = var.region
}

module "storage" {
  source        = "./storage"
  random_number = random_integer.ri.result
  region        = var.region
}

module "iam" {
  source                 = "./iam"
  random_number          = random_integer.ri.result
  access_group_email     = var.access_group_email
  project                = var.project
  bucket                 = module.storage.image_bucket
  logs_bucket            = module.storage.logs_bucket
  devops                 = var.devops
  enable_dns             = var.enable_dns
  pubsub_id              = module.ops.pubsub.id
  wif_issuer_uri         = format("https://%s:6443", local.hostnames["k8s"])
  gcp_secret_i_name      = var.gcp_secret_i_name
  wif_prv_k3s_conditions = var.wif_prv_k3s_conditions
}

module "passwords" {
  source = "./passwords"
}

module "sql" {
  source        = "./sql"
  zone          = var.zone
  region        = var.region
  random_number = random_integer.ri.result
  network_id    = module.network.vpc.network_id

  depends_on = [module.network.private_vpc_connection]
}

module "cluster" {
  source                       = "./cluster"
  project                      = var.project
  zone                         = var.zone
  region                       = var.region
  labels                       = var.labels
  random_number                = random_integer.ri.result
  sa_email                     = module.iam.gke_sa_email
  admin_ips                    = var.admin_ips
  k8s_api_hostname             = local.hostnames["k8s"]
  credentials                  = var.credentials
  db_username                  = module.sql.db_username
  db_password                  = module.sql.db_password
  db_host                      = module.sql.db_host
  subnet_cidr                  = module.network.vpc.subnets["${var.region}/outofschool"].ip_cidr_range
  subnet_name                  = var.subnet_name
  network_name                 = module.network.vpc.network_name
  k3s_version                  = var.k3s_version
  k3s_workers                  = var.k3s_workers
  k3s_masters                  = var.k3s_masters
  k3s_secret                   = var.k3s_secret
  root_ca_cert_pem             = module.k3s_certs.root_ca_cert_pem
  intermediate_cert_pem        = module.k3s_certs.intermediate_cert_pem
  intermediate_private_key_pem = module.k3s_certs.intermediate_private_key_pem
  server_private_key_pem       = module.k3s_certs.server_private_key_pem
  server_cert_pem              = module.k3s_certs.server_cert_pem
  client_private_key_pem       = module.k3s_certs.client_private_key_pem
  client_cert_pem              = module.k3s_certs.client_cert_pem
  cluster_ca_certificate       = base64encode(module.k3s_certs.cluster_ca_certificate)
  client_certificate           = base64encode(module.k3s_certs.client_certificate)
  client_key                   = base64encode(module.k3s_certs.client_key)
  lb_internal_address          = google_compute_address.lb_internal.address
  lb_address                   = google_compute_address.lb.address
  depends_on = [
    module.k3s_certs
  ]
}

module "k8s" {
  source                       = "./k8s"
  project                      = var.project
  zone                         = var.zone
  admin_ips                    = var.admin_ips
  uptime_source_ips            = var.uptime_source_ips
  sql_root_pass                = module.passwords.sql_root_pass
  sql_api_pass                 = module.passwords.sql_api_pass
  sql_auth_pass                = module.passwords.sql_auth_pass
  sql_migrations_pass          = module.passwords.sql_migrations_pass
  sql_dev_qc_password          = module.passwords.sql_dev_qc_password
  es_admin_pass                = module.passwords.es_admin_pass
  es_api_pass                  = module.passwords.es_api_pass
  redis_pass                   = module.passwords.redis_pass
  csi_sa_email                 = module.iam.csi_sa_email
  csi_sa_key                   = module.iam.csi_sa_key
  letsencrypt_email            = var.letsencrypt_email
  phpmyadmin_hostname          = local.hostnames["phpmyadmin"]
  kibana_hostname              = local.hostnames["kibana"]
  elastic_hostname             = local.hostnames["elastic"]
  enable_ingress_http          = var.enable_ingress_http
  pull_sa_key                  = module.iam.pull_sa_key
  pull_sa_email                = module.iam.pull_sa_email
  lb_internal_address          = google_compute_address.lb_internal.address
  front_hostname               = local.hostnames["front"]
  app_hostname                 = local.hostnames["app"]
  auth_hostname                = local.hostnames["auth"]
  sendgrid_key                 = var.sendgrid_key
  geo_apikey                   = var.geo_apikey
  enable_dns                   = var.enable_dns
  ingress_ip                   = module.network.ingress_ip
  dns_sa_key                   = module.iam.dns_sa_key
  openiddict_introspection_key = module.passwords.openiddict_introspection_key
  sender_email                 = var.sender_email
  es_user_rmon_password        = module.passwords.es_user_rmon_password
  es_dev_qc_password           = module.passwords.es_dev_qc_password
  webapi_sa_key                = module.iam.webapi_sa_key
  images_bucket                = module.storage.image_bucket
  oauth2_github_client_id      = var.oauth2_github_client_id
  oauth2_github_client_secret  = var.oauth2_github_client_secret
  oauth2_github_org            = var.oauth2_github_org
  oauth2_github_teams          = var.oauth2_github_teams
  sso_hostname                 = local.hostnames["sso"]
  staging_domain               = var.staging_domain
  aws_access_key_id            = var.aws_access_key_id
  aws_secret_access_key        = var.aws_secret_access_key
  s3_host                      = var.s3_host
  s3_bucket                    = var.s3_bucket
  storage_provider             = var.storage_provider
  wif_provider_name            = module.iam.wif_provider_name
  secret_reader_sa_email       = module.iam.secret_reader_sa_email
  gcp_secret_i_name            = var.gcp_secret_i_name
  aikom_api_url                = var.aikom_api_url
  aikom_client_id              = var.aikom_client_id
  aikom_client_secret          = var.aikom_client_secret
  aikom_token_endpoint         = var.aikom_token_endpoint
  external_auth_client_id      = var.external_auth_client_id
  external_auth_client_secret  = var.external_auth_client_secret
  mariadb_config               = var.mariadb_config
  depends_on = [
    module.cluster
  ]
}

module "secrets" {
  source                     = "./secrets"
  sql_api_pass               = module.passwords.sql_api_pass
  sql_auth_pass              = module.passwords.sql_auth_pass
  es_api_pass                = module.passwords.es_api_pass
  redis_pass                 = module.passwords.redis_pass
  labels                     = var.labels
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
  redis_secret                 = module.secrets.redis_secret
  sendgrid_key_secret          = module.secrets.sendgrid_key_secret
  bucket                       = module.storage.image_bucket
  github_front_secret          = module.secrets.github_front_secret
  github_back_secret           = module.secrets.github_back_secret
  github_token_secret          = module.secrets.github_token_secret
  geo_key_secret               = module.secrets.geo_key_secret
  random_number                = random_integer.ri.result
  network_id                   = module.network.vpc.network_id
  kube_secret                  = module.k3s_certs.secret_name
  private_ip_range             = module.network.private_ip_range
  front_hostname               = local.hostnames["front"]
  app_hostname                 = local.hostnames["app"]
  auth_hostname                = local.hostnames["auth"]
  gcf_bucket                   = module.storage.gcf_bucket
  gcf_sa_email                 = module.iam.gcf_sa_email
  discord_notification_webhook = var.discord_notification_webhook
  enable_cloud_run             = var.enable_cloud_run
  build_sa_id                  = module.iam.build_sa_id
  staging_domain               = var.staging_domain
  iit_libraries_url            = var.iit_libraries_url
  external_ca_json_url         = var.external_ca_json_url
  external_ca_p7b_url          = var.external_ca_p7b_url
  images_bucket                = module.storage.image_bucket
  storage_provider             = var.storage_provider
  s3_host                      = var.s3_host
  s3_bucket                    = var.s3_bucket
  secret_reader_sa_email       = module.iam.secret_reader_sa_email
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
  network_name  = module.network.vpc.network_name
  region        = var.region
  cloud_run_lb = {
    enable = true
    # TODO: Move to variables
    services = {
      frontend = {
        domain = local.hostnames["front"]
      }
      apiservice = {
        domain = local.hostnames["app"]
      }
      authservice = {
        domain = local.hostnames["auth"]
      }
    }
    ssl = true
  }
}

module "dns" {
  count      = var.enable_dns ? 1 : 0
  source     = "./dns"
  dns_domain = var.dns_domain
  labels     = var.labels
  ingress_ip = module.network.ingress_ip
  subdomains = [
    for name, subdomain in local.subdomains : subdomain if name != "k8s"
  ]
  k3s_xlb_address = google_compute_address.lb.address
  k3s_subdomain   = local.subdomains["k8s"]
}

module "k3s_certs" {
  source = "./k3s-certs"

  project_id          = var.project
  lb_internal_address = google_compute_address.lb_internal.address
}


