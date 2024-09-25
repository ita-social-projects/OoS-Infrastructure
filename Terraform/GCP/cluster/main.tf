module "masters" {
  source     = "./nodes"
  node_role  = "master"
  node_count = var.k3s_masters
  startup = templatefile("${path.module}/startup-master.sh", {
    ROOT_CA_PEM_CERT       = var.root_ca_cert_pem
    INTERMEDIATE_CA_PEM    = var.intermediate_cert_pem
    INTERMEDIATE_CA_KEY    = var.intermediate_private_key_pem
    SERVER_KEY             = var.server_private_key_pem
    SERVER_PEM             = var.server_cert_pem
    CLIENT_KEY             = var.client_private_key_pem
    CLIENT_PEM             = var.client_cert_pem
    db_username            = var.db_username
    db_password            = var.db_password
    db_host                = var.db_host
    token                  = random_id.token.hex
    random_number          = var.random_number
    external_hostname      = var.k8s_api_hostname
    external_lb_ip_address = var.lb_address
    internal_lb_ip_address = var.lb_internal_address
    cluster_cidr           = var.subnet_cidr
    k3s_version            = var.k3s_version
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
names+="${i}"
names+=" "
%{endfor~}
# Iterate through the list of instances
FS=' ' read -a list_names <<< "$${names}"
for name in "$${list_names[@]}"; do
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
  startup = templatefile("${path.module}/startup-worker.sh", {
    token         = random_id.token.hex
    random_number = var.random_number
    main_node     = var.lb_internal_address
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





