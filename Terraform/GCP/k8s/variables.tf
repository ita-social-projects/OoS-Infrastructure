variable "project" {
  type        = string
  description = "Your project"
}

variable "zone" {
  type        = string
  description = "Zone where the cluster was created"
}

variable "admin_ips" {
  type        = list(string)
  description = "Admin IPs to manage database if needed"
}

variable "sql_api_pass" {
  type = string
}

variable "sql_auth_pass" {
  type = string
}

variable "sql_root_pass" {
  type = string
}

variable "sql_migrations_pass" {
  type = string
}

variable "sql_dev_qc_password" {
  type = string
}

variable "es_admin_pass" {
  type = string
}

variable "es_api_pass" {
  type = string
}

variable "redis_pass" {
  type = string
}

variable "csi_sa_email" {
  type = string
}

variable "csi_sa_key" {
}

variable "letsencrypt_email" {
  type        = string
  description = "E-mail of letsencrypt user"
}

variable "phpmyadmin_hostname" {
  type        = string
  description = "Hostname for PHPMyAdmin"
}

variable "kibana_hostname" {
  type        = string
  description = "Hostname for Kibana"
}

variable "elastic_hostname" {
  type        = string
  description = "Hostname for Elastic"
}

variable "sso_hostname" {
  type        = string
  description = "Hostname for SSO/OAuth2"
}

variable "enable_ingress_http" {
  type = bool
}

variable "pull_sa_key" {
}

variable "pull_sa_email" {
}

variable "lb_internal_address" {
  type = string
}

variable "auth_hostname" {
  type = string
}

variable "app_hostname" {
  type = string
}

variable "front_hostname" {
  type = string
}

variable "sendgrid_key" {
  type = string
}

variable "geo_apikey" {
  type = string
}

variable "enable_dns" {
  type        = bool
  description = "Should we use managed hosted zone and dns challenge for Let's Encrypt"
}

variable "dns_sa_key" {
}

variable "ingress_ip" {
  type = string
}

variable "openiddict_introspection_key" {
  type = string
}

variable "uptime_source_ips" {
  type        = list(string)
  default     = []
  description = "Google uptime check ips"
}

variable "sender_email" {
  type = string
}

variable "es_user_rmon_password" {
  type = string
}

variable "es_dev_qc_password" {
  type = string
}

variable "mysql_agent_name" {
  description = "Mysql user for metricbeat monitoring"
  type        = string
  default     = "agent_monitoring"
}

variable "images_bucket" {
  type = string
}

variable "webapi_sa_key" {
}

variable "oauth2_github_client_id" {
  type = string
}

variable "oauth2_github_client_secret" {
  type = string
}

variable "oauth2_github_org" {
  type = string
}

variable "oauth2_github_teams" {
  type = list(string)
}

variable "staging_domain" {
  type = string
}

variable "discord_notification_secret_name" {
  type    = string
  default = "discord-notification"
}

variable "aws_access_key_id" {
  type = string
}

variable "aws_secret_access_key" {
  type = string
}

variable "s3_host" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "storage_provider" {
  type = string
  validation {
    condition     = contains(["AmazonS3", "GoogleCloud"], var.storage_provider)
    error_message = "Valid value is one of the following: AmazonS3, GoogleCloud."
  }
}

variable "wif_provider_name" {
  type = string
}

variable "secret_reader_sa_email" {
  type = string
}

variable "wif_credentials" {
  default = {
    cm_name            = "wif-credentials-configuration"
    namespace          = "kube-system"
    gsp_ksa_file       = "wif_credentials_config.json"
    gcp_ksa_token_path = "/var/run/secrets/sts.googleapis.com/serviceaccount"
  }
}

variable "gcp_secret_i_name" {
  type = string
}

variable "aikom_api_url" {
  type = string
}

variable "aikom_client_id" {
  type      = string
  sensitive = true
}

variable "aikom_client_secret" {
  type      = string
  sensitive = true
}

variable "aikom_token_endpoint" {
  type = string
}

variable "external_auth_client_id" {
  type      = string
  sensitive = true
}

variable "external_auth_client_secret" {
  type      = string
  sensitive = true
}

variable "mariadb_config" {
  type = object({
    database = string
    version  = string
    users = object({
      webapi     = string,
      auth       = string,
      migrations = string,
      devqc      = string
    })
  })
}
