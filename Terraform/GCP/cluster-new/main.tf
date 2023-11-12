module "masters" {
  source     = "./nodes"
  node_role  = "master"
  node_count = var.k3s_masters
  shutdown   = file("${path.module}/shutdown.sh")
  startup = templatefile("${path.module}/startup-master.sh", {
    ROOT_CA_PRIVATE_KEY    = tls_private_key.root_key.private_key_pem,
    ROOT_CA_PEM_CERT       = tls_self_signed_cert.root_ca.cert_pem,
    INTERMEDIATE_CA_PEM    = tls_locally_signed_cert.intermediate.cert_pem,
    INTERMEDIATE_CA_KEY    = tls_private_key.intermediate.private_key_pem,
    SERVER_KEY             = tls_private_key.server.private_key_pem,
    SERVER_PEM             = tls_locally_signed_cert.server.cert_pem,
    CLIENT_KEY             = tls_private_key.client.private_key_pem,
    CLIENT_PEM             = tls_locally_signed_cert.client.cert_pem,
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
    ccm_manifest           = file("${path.module}/templates/ccm.yaml")
  })
  random_number = var.random_number
  labels        = var.labels
  tags          = var.tags
  zone          = var.zone
  sa_email      = var.sa_email
  network_name  = var.network_name
  subnet_name   = var.subnet_name
}

locals {
  labelFilter     = "labels.startup-done=${var.random_number}"
  formatNamesOnly = "csv [no-heading] (name)"
}

resource "null_resource" "wait_for_instances" {
  triggers = {
    cluster_template_id = module.masters.template_id
  }

  provisioner "local-exec" {
    command = <<EOF
LABELED_INSTANCES=0
RUNNING_INSTANCES=0
gcloud auth activate-service-account --key-file="${var.credentials}"
while [ "$LABELED_INSTANCES" -ne "${length(module.masters.names)}" ]
do
  sleep 5
    LABELED_INSTANCES=$( \
    gcloud compute instances list \
      --filter="${local.labelFilter}" \
      --format="${local.formatNamesOnly}" \
      --project ${var.project} | wc -l )
    echo $LABELED_INSTANCES / \
      ${length(module.masters.names)} \
      instances initialized
done

# Remove label
declare -a names
%{for i in module.masters.names~}
names+=${i}
%{endfor~}
# Iterate through the list of instances
for name in "$${names[@]}"; do
  echo "Proccesing instance $name"
  gcloud compute instances remove-labels $name --project ${var.project} --zone ${var.zone} --labels=startup-done
done
EOF
  }
}

module "workers" {
  count      = var.k3s_workers > 0 ? 1 : 0
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
  subnet_name   = var.subnet_name

  depends_on = [
    google_compute_forwarding_rule.k3s_api_internal
  ]
}
