module "masters" {
  source     = "./nodes"
  node_role  = "master"
  node_count = var.k3s_masters
  shutdown   = file("${path.module}/shutdown.sh")
  startup = templatefile("${path.module}/startup-master.sh", {
    db_username            = var.db_username
    db_password            = var.db_password
    db_host                = var.db_host
    token                  = random_id.token.hex
    random_number          = var.random_number
    external_hostname      = var.k8s_api_hostname
    external_lb_ip_address = google_compute_address.lb.address
    internal_lb_ip_address = google_compute_address.lb_internal.address
    cluster_cidr           = var.subnet_cidr
    k3s_version            = var.k3s_version
  })
  random_number = var.random_number
  labels        = var.labels
  tags          = var.tags
  zone          = var.zone
  sa_email      = var.sa_email
  network_name  = var.network_name
}

locals {
  labelFilter     = "labels.startup-done=${var.random_number}"
  formatNamesOnly = "csv [no-heading] (name)"
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [module.masters]

  destroy_duration = "60s"
}

resource "null_resource" "wait_for_instances" {
  depends_on = [
    time_sleep.wait_60_seconds
  ]
  triggers = {
    cluster_template_id = module.masters.template_id
  }

  provisioner "local-exec" {
    command = <<EOF
LABELED_INSTANCES=0
gcloud auth activate-service-account --key-file="${var.credentials}"
while [ "$LABELED_INSTANCES" -ne "${length(module.masters.names)}" ]
do
  sleep 10
  LABELED_INSTANCES=$( \
    gcloud compute instances list \
      --filter="${local.labelFilter}" \
      --format="${local.formatNamesOnly}" \
      --project ${var.project} | wc -l )
    echo $LABELED_INSTANCES / \
      ${length(module.masters.names)} \
      instances initialized
done
EOF
  }
}

module "workers" {
  source     = "./nodes"
  node_role  = "worker"
  node_count = var.k3s_workers
  shutdown   = file("${path.module}/shutdown-worker.sh")
  startup = templatefile("${path.module}/startup-worker.sh", {
    token         = random_id.token.hex
    random_number = var.random_number
    main_node     = google_compute_address.lb_internal.address
    k3s_version   = var.k3s_version
  })
  random_number = var.random_number
  labels        = var.labels
  tags          = var.tags
  zone          = var.zone
  sa_email      = var.sa_email
  network_name  = var.network_name

  depends_on = [
    google_compute_forwarding_rule.k3s_api_internal
  ]
}

resource "null_resource" "get_k8s_config" {
  depends_on = [
    null_resource.wait_for_instances,
    google_compute_forwarding_rule.k8s-api
  ]

  provisioner "local-exec" {
    command = <<EOF
gcloud compute scp ${module.masters.names[0]}:/etc/rancher/k3s/k3s.yaml ${abspath(path.module)}/kubeconfig.yaml \
  --zone ${var.zone} \
  --project ${var.project}
sed -i '' 's/127.0.0.1:6443/${google_compute_address.lb.address}:6443/g' ${abspath(path.module)}/kubeconfig.yaml
EOF
  }
}
