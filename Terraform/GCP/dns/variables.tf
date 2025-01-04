variable "labels" {
  type        = map(string)
  description = "A mapping of labels to assign to the resources."
}

variable "dns_domain" {
  type        = string
  description = "DNS Name for the managed hosted zone. Without the dot (.) in the end"
  default     = ""
}

variable "ingress_ip" {
  type = string
}

variable "subdomains" {
  type        = list(string)
  default     = []
  description = "List of subdomains that need to be mapped to ingress ip address"
}

variable "k3s_lb_address" {
  type        = string
  description = "Load Balancer IP address for K3s cluster"
}

variable "k3s_subdomain" {
  type        = string
  description = "Subdomain name for K3s cluster"
  default     = "k3s"
}
