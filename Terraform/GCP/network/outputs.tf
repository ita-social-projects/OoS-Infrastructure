output "vpc" {
  value = module.vpc
}

output "private_vpc_connection" {
  value = google_service_networking_connection.private_vpc_connection
}

output "private_ip_range" {
  value = "${google_compute_global_address.private_ip.address}/${google_compute_global_address.private_ip.prefix_length}"
}

output "ingress_ip" {
  value = google_compute_address.ingress_ip.address
}
