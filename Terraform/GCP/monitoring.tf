locals {
  uptime = {
    Elasticsearch = {
      host    = "elastic.oos.dmytrominochkin.cloud"
      period  = "60s"
      regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA", "USA_IOWA"]
      path    = "/_cluster/health"
    }
  }

  notification = {
    display_name = "Discord"
    type         = "pubsub"
    labels       = { type = "pubsub" }
  }
  topic_name = "monitoring-notification"
  file_name  = "discord-notification.zip"
}

module "uptime-check" {
  for_each = local.uptime
  source   = "terraform-google-modules/cloud-operations/google//modules/simple-uptime-check"
  version  = "~> 0.4"

  project_id                = var.project
  uptime_check_display_name = "${each.key} Uptime check"
  protocol                  = "HTTPS"
  period                    = each.value.period
  selected_regions          = each.value.regions
  path                      = each.value.path
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

module "pubsub" {
  source     = "terraform-google-modules/pubsub/google"
  version    = "~> 6.0"
  project_id = var.project
  topic      = local.topic_name
  topic_labels = {
    name = "alerting"
  }
}

resource "google_storage_bucket" "bucket" {
  name                        = "gcf-v2-${var.project}-notification-channel"
  location                    = var.region
  storage_class               = "REGIONAL"
  uniform_bucket_level_access = true
  project                     = var.project

}

resource "google_storage_bucket_object" "source" {
  name   = local.cluster_ca_certificate
  bucket = google_storage_bucket.bucket.name
  source = "../../helpers/${local.file_name}"
}

module "cloud-functions_example_cloud_function2_pubsub_trigger" {
  source  = "GoogleCloudPlatform/cloud-functions/google"
  version = "0.4.1"

  project_id        = var.project
  function_name     = "gcp-uptime-notification"
  function_location = var.region
  runtime           = "python38"
  entrypoint        = "cloud_event"
  storage_source = {
    bucket     = google_storage_bucket.bucket.name
    object     = google_storage_bucket_object.source.name
    generation = null
  }
  event_trigger = {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    service_account_email = null
    pubsub_topic          = module.pubsub.id
    retry_policy          = "RETRY_POLICY_RETRY"
    event_filters         = null
  }
}


