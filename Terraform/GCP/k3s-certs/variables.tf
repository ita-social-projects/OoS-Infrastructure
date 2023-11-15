variable "k3s_secret" {
  type    = string
  default = "kubeconfig"
}

variable "labels" {
  type        = map(string)
  default     = {}
  description = "A mapping of labels to assign to the resources."
}

