variable "project" {
  type        = string
  description = "Your GCP Project"
}

variable "network_id" {
  type = string
}

variable "random_number" {
  type = number
}

variable "notification_email" {
  type = string
}

variable "gcf_bucket" {
  type = string
}

variable "discord_webhook" {
  type = string
}

variable "region" {
  type        = string
  description = "Region to create the resources in"
}

variable "eck_password" {
  type = string
  description = "Password for eck remote_monitoring_user"
}
