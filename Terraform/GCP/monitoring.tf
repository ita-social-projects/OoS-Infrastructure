locals {
    uptime = {
        Elasticsearch = {
            host = "elastic.oos.dmytrominochkin.cloud"
            period = "60s"
            regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA", "USA_IOWA"]
            path = "/_cluster/health"

        }
    }

    notification = {
        display_name = "Discord"
        type = "pubsub"
        labels = { type = "pubsub"}
    }
}

module "uptime-check" {
  for_each = local.uptime
  source  = "terraform-google-modules/cloud-operations/google//modules/simple-uptime-check"
  version = "~> 0.4"

  project_id                = var.project
  uptime_check_display_name = "${each.key} Uptime check"
  protocol                  = "HTTPS"
  period = each.value.period
  selected_regions = each.value.regions
  path = each.value.path
  auth_info = {
    username = "elastic"
    password = ""
  }

  monitored_resource = {
    monitored_resource_type = "uptime_url"
    labels = {
      "project_id" = var.project
      "host"       = each.value.host
    }
  }

  notification_channels = [local.notification]

}