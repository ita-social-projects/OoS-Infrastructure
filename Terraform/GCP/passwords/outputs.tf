output "sql_root_pass" {
  value = random_password.sql_root_pass.result
}

output "sql_api_pass" {
  value = random_password.sql_api_pass.result
}

output "sql_auth_pass" {
  value = random_password.sql_auth_pass.result
}

output "sql_migrations_pass" {
  value = random_password.sql_migrations_pass.result
}

output "sql_dev_qc_password" {
  value = random_password.sql_dev_qc_password.result
}

output "es_admin_pass" {
  value = random_password.es_admin_pass.result
}

output "es_api_pass" {
  value = random_password.es_api_pass.result
}

output "redis_pass" {
  value = random_password.redis_pass.result
}

output "openiddict_introspection_key" {
  value = random_password.openiddict_introspection_key.result
}

output "es_user_rmon_password" {
  value = random_password.es_user_rmon_password.result
}

output "es_dev_qc_password" {
  value = random_password.es_dev_qc_password.result
}
