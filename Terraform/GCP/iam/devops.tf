locals {
  edit_roles = [
    "roles/compute.osAdminLogin",
    "roles/secretmanager.secretVersionManager",
    "roles/compute.loadBalancerServiceUser",
    "roles/compute.networkUser",
    "roles/compute.instanceAdmin",
    "roles/storage.admin",
    "roles/artifactregistry.repoAdmin",
    "roles/artifactregistry.createOnPushRepoAdmin",
    "roles/cloudbuild.builds.editor",
    "roles/run.developer",
    "roles/secretmanager.secretAccessor",
    "roles/cloudsql.editor",
    "roles/iap.tunnelResourceAccessor"
  ]

  devops_roles = distinct(
    flatten([
      for devops in var.devops : [
        for role in local.edit_roles : {
          devops = devops
          role   = role
        }
      ]
  ]))

  discord_sa_roles = [
    "roles/eventarc.eventReceiver",
    "roles/pubsub.publisher",
    "roles/pubsub.viewer",
  ]
}

resource "google_service_account_iam_member" "vm_sa_user" {
  for_each           = toset(var.devops)
  service_account_id = google_service_account.gke.name
  role               = "roles/iam.serviceAccountUser"
  member             = "user:${each.value}"
}

resource "google_project_iam_member" "devops_roles" {
  for_each = { for element in local.devops_roles : "${element.devops}.${element.role}" => element }
  project  = var.project
  role     = each.value.role
  member   = "user:${each.value.devops}"
}
