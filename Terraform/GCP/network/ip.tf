resource "google_compute_global_address" "private_ip" {
  name          = "peering-private-ip"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = module.vpc.network_id
  #   TODO: Remove static IP value when re-creating the network
  address = "10.206.0.0"
}

resource "google_compute_address" "ingress_ip" {
  name         = "ingress-lb-ip"
  address_type = "EXTERNAL"
  network_tier = "PREMIUM"
}
