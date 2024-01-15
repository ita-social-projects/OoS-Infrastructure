locals {
  whitelist_ips = concat(var.admin_ips, var.uptime_source_ips)
}

