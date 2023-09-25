module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 5.0"

  project_id   = var.project
  network_name = "outofschool-${var.random_number}"
  routing_mode = "REGIONAL"

  subnets = [
    {
      subnet_name               = "outofschool"
      subnet_ip                 = "10.132.0.0/20"
      subnet_region             = var.region
      subnet_private_access     = "true"
      subnet_flow_logs          = "true"
      subnet_flow_logs_interval = "INTERVAL_10_MIN"
      subnet_flow_logs_sampling = 0.5
      subnet_flow_logs_metadata = "EXCLUDE_ALL_METADATA"
      subnet_flow_logs_filter   = "false"
    }
  ]

  firewall_rules = [
    {
      name = "fw-outofschool-allow-internal"

      direction = "INGRESS"

      allow = [
        {
          protocol = "tcp"
          ports    = ["0-65535"]
        },
        {
          protocol = "udp"
          ports    = ["0-65535"]
        },
        {
          protocol = "icmp"
          ports    = []
        }
      ]

      ranges   = ["10.132.0.0/20"] #10.128.0.0/9
      priority = 65534
    }
  ]
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 2.0.0"
  project = var.project
  name    = "oos-cloud-router"
  network = module.vpc.network_name
  region  = var.region

  nats = [{
    name = "oos-nat-gateway"
    log_config = {
      enable = false
      filter = "ALL"
    }
  }]
}

resource "google_service_networking_connection" "private_vpc_connection" {
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip.name]
  network                 = module.vpc.network_id
}
