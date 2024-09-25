output "db_username" {
  value = google_sql_user.state.name
}

output "db_password" {
  value = google_sql_user.state.password
}

output "db_host" {
  value = google_sql_database_instance.state.private_ip_address
}
