resource "google_compute_instance_template" "k3s" {
  name_prefix = "k3s-${var.node_role}-${var.random_number}-"
  description = "This template is used to create k3s ${var.node_role} instances."

  tags = var.tags

  labels = var.labels

  instance_description = "${var.node_role} instance"
  machine_type         = var.machine_type["e2custom10240"]
  can_ip_forward       = true

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  disk {
    source_image = data.google_compute_image.ubuntu.self_link
    auto_delete  = true
    boot         = true
    disk_size_gb = 30
    disk_type    = "pd-standard"
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
  }

  metadata = {
    block-project-ssh-keys = true
    enable-oslogin         = "TRUE"
  }

  metadata_startup_script = var.startup

  service_account {
    email  = var.sa_email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      labels,
      metadata_startup_script,
    ]
  }
}

resource "google_compute_health_check" "k3s" {
  count = var.node_role == "master" ? 1 : 0
  name  = "k3s-port-hc-${var.node_role}-${var.random_number}"

  timeout_sec         = 5
  check_interval_sec  = 30
  healthy_threshold   = 1
  unhealthy_threshold = 5

  ssl_health_check {
    port         = "6443"
    proxy_header = "NONE"
  }
}

resource "google_compute_instance_group_manager" "k3s" {
  count = var.node_role == "master" ? 1 : 0
  name  = "k3s-igm-${var.node_role}-${var.random_number}"

  base_instance_name = "k3s-${var.node_role}"
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.k3s.id
  }

  target_size = 0

  auto_healing_policies {
    health_check      = google_compute_health_check.k3s[0].id
    initial_delay_sec = 300
  }

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 0
    max_unavailable_fixed = 1
    replacement_method    = "RECREATE"
  }

  lifecycle {
    ignore_changes = [target_size]
  }
}

resource "google_compute_instance_group_manager" "k3s_worker" {
  count = var.node_role == "worker" ? 1 : 0
  name  = "k3s-igm-${var.node_role}-${var.random_number}"

  base_instance_name = "k3s-${var.node_role}"
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.k3s.id
  }

  target_size = var.node_count

  update_policy {
    type                  = "PROACTIVE"
    minimal_action        = "REPLACE"
    max_surge_fixed       = 0
    max_unavailable_fixed = 1
    replacement_method    = "RECREATE"
  }
}

resource "google_compute_per_instance_config" "k3s" {
  for_each               = var.node_role == "master" ? toset(local.full_names) : []
  zone                   = google_compute_instance_group_manager.k3s[0].zone
  instance_group_manager = google_compute_instance_group_manager.k3s[0].name
  name                   = each.key
  minimal_action         = "REPLACE"
  preserved_state {
    metadata = {
      instance_template = google_compute_instance_template.k3s.self_link
    }
  }
}

resource "google_compute_per_instance_config" "k3s_worker" {
  for_each               = var.node_role == "worker" ? toset(local.full_names) : []
  zone                   = google_compute_instance_group_manager.k3s_worker[0].zone
  instance_group_manager = google_compute_instance_group_manager.k3s_worker[0].name
  name                   = each.key
  minimal_action         = "REPLACE"
  preserved_state {
    metadata = {
      instance_template = google_compute_instance_template.k3s.self_link
    }
  }
}

locals {
  full_names = [
    for i in range(1, var.node_count + 1) : format("k3s-%s%d", var.node_role, i)
  ]
}
