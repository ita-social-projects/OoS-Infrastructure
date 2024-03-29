variable "project" {
  type        = string
  description = "Your project"
}

variable "credentials" {
  type        = string
  description = "Path to GCP Service Account key JSON"
}

variable "region" {
  type        = string
  description = "Region to create the resources in"
}

variable "zone" {
  type        = string
  description = "Zone to create the database in"
}

variable "random_number" {
  type = number
}

variable "sa_email" {
  type = string
}

variable "admin_ips" {
  type        = list(string)
  description = "Admin IPs to manage database if needed"
}

variable "tags" {
  type        = list(string)
  description = "A list of network tags to assign to the resources."
  default     = ["mysql", "elastic"]
}

variable "labels" {
  type        = map(string)
  description = "A mapping of labels to assign to the resources."
}

variable "k8s_api_hostname" {
  description = "Hostname of K8S API"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "db_host" {
  type = string
}

variable "subnet_cidr" {
  type = string
}

variable "subnet_name" {
  type = string
}

variable "network_name" {
  type = string
}

variable "k3s_version" {
  type = string
}

variable "k3s_masters" {
  type = number
}

variable "k3s_workers" {
  type = number
}

variable "k3s_secret" {
  type    = string
  default = "kubeconfig"
}

variable "k3s_port" {
  type    = string
  default = "6443"
}

variable "root_ca_cert_pem" {
  type = string
}

variable "intermediate_cert_pem" {
  type = string
}

variable "intermediate_private_key_pem" {
  type = string
}

variable "server_private_key_pem" {
  type = string
}

variable "server_cert_pem" {
  type = string
}

variable "client_private_key_pem" {
  type = string
}

variable "client_cert_pem" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "lb_address" {
  type = string
  default = ""
}

variable "lb_internal_address" {
  type = string
  default = ""
}


