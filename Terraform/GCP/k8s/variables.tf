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

variable "mysql_user" {
  type    = string
  default = "oos"
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
