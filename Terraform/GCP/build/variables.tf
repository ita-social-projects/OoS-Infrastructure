variable "random_number" {
  type = number
}

variable "app_sa_email" {
  type = string
}

variable "auth_sa_email" {
  type = string
}

variable "front_sa_email" {
  type = string
}

variable "api_secret" {
  type = string
}

variable "auth_secret" {
  type = string
}

variable "es_api_pass_secret" {
  type = string
}

variable "redis_secret" {
  type = string
}

variable "sendgrid_key_secret" {
  type = string
}

variable "project" {
  type        = string
  description = "Your project"
}

variable "zone" {
  type        = string
  description = "Zone to create the resources in"
}

variable "region" {
  type        = string
  description = "Region to create the resources in"
}

variable "bucket" {
  type = string
}

variable "github_front_secret" {
  type = string
}

variable "github_back_secret" {
  type = string
}

variable "github_token_secret" {
  type = string
}

variable "geo_key_secret" {
  type = string
}

variable "network_id" {
  type = string
}

variable "private_ip_range" {
  type = string
}

variable "tags" {
  type        = list(string)
  description = "A list of network tags to assign to the resources."
  default     = ["mysql", "elastic"]
}

variable "kube_secret" {
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

variable "gcf_bucket" {
  type = string
}

variable "gcf_sa_email" {
  type = string
}

variable "discord_notification_webhook" {
  type = string
}

variable "enable_cloud_run" {
  type = bool
}

variable "build_sa_id" {
  type = string
}

variable "staging_domain" {
  type = string
}

variable "iit_libraries_url" {
  type = string
}
