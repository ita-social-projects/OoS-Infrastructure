resource "google_compute_address" "lb_internal" {
  name         = "k3s-static-new-${random_integer.ri.result}-internal"
  address_type = "INTERNAL"
  purpose      = "GCE_ENDPOINT"
  region       = var.region
  subnetwork   = var.subnet_name
}

resource "google_compute_address" "lb" {
  name = "k3s-static-new-${random_integer.ri.result}"
}
