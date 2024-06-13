resource "random_password" "sql_root_pass" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "sql_api_pass" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "sql_auth_pass" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "es_admin_pass" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "es_api_pass" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "redis_pass" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "openiddict_introspection_key" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "es_user_rmon_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "random_password" "es_dev_qc_password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
