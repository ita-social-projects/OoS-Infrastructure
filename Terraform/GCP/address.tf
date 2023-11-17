resource "google_compute_address" "lb_internal" {
  name         = "k3s-static-${random_integer.ri.result}-internal"
  address_type = "INTERNAL"
  address      = "10.132.0.14"
  purpose      = "GCE_ENDPOINT"
  region       = var.region
  subnetwork   = var.subnet_name
}

resource "google_compute_address" "lb" {
  name = "k3s-static-${random_integer.ri.result}"
  address = "34.77.193.10"
}
