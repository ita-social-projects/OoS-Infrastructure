output "es_api_secret" {
  value = var.enable_cloud_run ? "${element(local.es_api_list, length(local.es_api_list) - 3)}:${element(local.es_api_list, length(local.es_api_list) - 1)}" : ""
}

output "sql_api_secret" {
  value = var.enable_cloud_run ? "${element(local.api_list, length(local.api_list) - 3)}:${element(local.api_list, length(local.api_list) - 1)}" : ""
}

output "sql_auth_secret" {
  value = var.enable_cloud_run ? "${element(local.auth_list, length(local.auth_list) - 3)}:${element(local.auth_list, length(local.auth_list) - 1)}" : ""
}

output "redis_secret" {
  value = var.enable_cloud_run ? "${element(local.redis_list, length(local.redis_list) - 3)}:${element(local.redis_list, length(local.redis_list) - 1)}" : ""
}

output "sendgrid_key_secret" {
  value = var.enable_cloud_run ? "${element(local.sendgrid_key_list, length(local.sendgrid_key_list) - 3)}:${element(local.sendgrid_key_list, length(local.sendgrid_key_list) - 1)}" : ""
}

output "geo_key_secret" {
  value = var.enable_cloud_run ? "${element(local.geo_key_list, length(local.geo_key_list) - 3)}:${element(local.geo_key_list, length(local.geo_key_list) - 1)}" : ""
}

output "github_front_secret" {
  value = google_secret_manager_secret_version.github_front_secret.name
}

output "github_back_secret" {
  value = google_secret_manager_secret_version.github_back_secret.name
}

output "github_token_secret" {
  value = google_secret_manager_secret_version.github_token_secret.name
}

output "remote_monitoring_eck_secret" {
  value = google_secret_manager_secret_version.eck.secret_data
}

