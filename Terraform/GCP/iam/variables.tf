variable "random_number" {
  type = number
}

variable "access_group_email" {
  type = string
}

variable "project" {
  type        = string
  description = "Your project"
}

variable "bucket" {
  type = string
}

variable "logs_bucket" {
  type = string
}

variable "devops" {
  type        = list(string)
  description = "E-mails of devops with edit permissions"
}

variable "enable_dns" {
  type        = bool
  description = "Should we use managed hosted zone and dns challenge for Let's Encrypt"
}

variable "pubsub_id" {
  type        = string
  description = "Pubsub id for role publishing"
}

variable "discord_notification_secret_name" {
  type    = string
  default = "discord-notification"
}

variable "wif_issuer_uri" {
  type        = string
  description = "Workload issuer uri"
  default     = ""
}

variable "google_secret_name_k3s_jwks" {
  type        = string
  description = "Google secret name for k3s jwks"
  default     = "k3s-jwks"
}
