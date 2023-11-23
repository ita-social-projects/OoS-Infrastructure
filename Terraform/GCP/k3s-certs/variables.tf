variable "k3s_secret" {
  type    = string
  default = "kubeconfig"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "A mapping of labels to assign to the resources."
}

variable "lb_internal_address" {
  type = string
  default = ""
}

variable "k3s_port" {
  type    = string
  default = "6443"
}

variable "project_id" {
  type = string
}
