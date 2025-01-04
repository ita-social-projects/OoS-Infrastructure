resource "google_dns_managed_zone" "oos_zone" {
  name        = "oos-zone"
  dns_name    = "${var.dns_domain}."
  description = "OutOfSchool DNS Zone"
  labels      = var.labels
}

resource "google_dns_record_set" "ingress_subdomains" {
  for_each = toset(var.subdomains)
  name     = each.key == "" ? google_dns_managed_zone.oos_zone.dns_name : "${each.key}.${google_dns_managed_zone.oos_zone.dns_name}"
  type     = "A"
  ttl      = 300

  managed_zone = google_dns_managed_zone.oos_zone.name

  rrdatas = [var.ingress_ip]
}

resource "google_dns_record_set" "k3s_lb" {
  name = "${var.k3s_subdomain}.${google_dns_managed_zone.oos_zone.dns_name}"
  type = "A"
  ttl  = 300

  managed_zone = google_dns_managed_zone.oos_zone.name

  rrdatas = [var.k3s_xlb_address]
}
