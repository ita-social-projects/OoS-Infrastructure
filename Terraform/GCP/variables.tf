variable "project" {
  type        = string
  description = "Your GCP Project"
}

variable "region" {
  type        = string
  description = "Region to create the resources in"
}

variable "zone" {
  type        = string
  description = "Zone to create the resources in"
}

variable "credentials" {
  type        = string
  description = "Path to GCP Service Account key JSON"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "A mapping of labels to assign to the resources."
}

variable "access_group_email" {
  type        = string
  default     = "none"
  description = "Google Group that will receive access permissions"
}

variable "admin_ips" {
  type        = list(string)
  default     = []
  description = "Admin IPs to manage database if needed"
}

variable "auth_subdomain" {
  type        = string
  default     = "none"
  description = "Identity Server custom subdomain"
}

variable "app_subdomain" {
  type        = string
  default     = "none"
  description = "Web application custom subdomain"
}

variable "front_subdomain" {
  type        = string
  default     = ""
  description = "Frontend custom subdomain"
}

variable "devops" {
  type        = list(string)
  description = "E-mails of devops with edit permissions"
}

variable "letsencrypt_email" {
  type        = string
  description = "E-mail of letsencrypt user"
}

variable "k8s_api_subdomain" {
  type        = string
  description = "subdomain for K8S API"
}

variable "phpmyadmin_subdomain" {
  type        = string
  description = "subdomain for PHPMyAdmin"
}

variable "kibana_subdomain" {
  type        = string
  description = "subdomain for Kibana"
}

variable "elastic_subdomain" {
  type        = string
  description = "subdomain for Elastic"
}

variable "sso_subdomain" {
  type        = string
  description = "subdomain for SSO/OAuth2"
}

variable "sender_email" {
  type        = string
  description = "Outgoing mail"
}

variable "sendgrid_key" {
  type        = string
  description = "Outgoing mail api key"
}

variable "github_front_deploy_base64" {
  type        = string
  description = "Github Deploy key"
}

variable "github_back_deploy_base64" {
  type        = string
  description = "Github Deploy key"
}

variable "github_access_token" {
  type        = string
  description = "Github Access Token to create releases"
}

variable "enable_cloud_run" {
  type    = bool
  default = false
}

variable "geo_apikey" {
  type = string
}

variable "enable_ingress_http" {
  type = bool
}

variable "k3s_version" {
  type = string
}

variable "k3s_masters" {
  type    = number
  default = 2
}

variable "k3s_workers" {
  type    = number
  default = 0
}

variable "discord_notification_webhook" {
  type = string
}

variable "dns_domain" {
  type        = string
  description = "DNS Name for the managed hosted zone. Without the dot (.) in the end"
  default     = ""
}

variable "enable_dns" {
  type        = bool
  default     = false
  description = "Should we use managed hosted zone and dns challenge for Let's Encrypt"
}

variable "k3s_secret" {
  type    = string
  default = "kubeconfig"
}

variable "subnet_name" {
  type    = string
  default = "outofschool"
}

variable "k3s_port" {
  type    = string
  default = "6443"
}

variable "uptime_source_ips" {
  type        = list(string)
  default     = []
  description = "Google uptime check ips"
}

variable "gcp_monitoring_discord_webhook" {
  type = string
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
  type    = string
  default = ""
}

variable "kibana_alerting_discord_webhook" {
  type = string
}

variable "iit_libraries_url" {
  type = string
}

variable "external_ca_json_url" {
  type = string
}

variable "external_ca_p7b_url" {
  type = string
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

variable "gcp_secret_i_name" {
  type = string
}
