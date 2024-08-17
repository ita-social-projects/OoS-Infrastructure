locals {
  uptime = {
    Elasticsearch = {
      host    = "elastic.oos.dmytrominochkin.cloud"
      period  = "60s"
      regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA", "USA_IOWA"]
      path    = "/_cluster/health"
    }
    Kibana = {
      host    = "kibana.oos.dmytrominochkin.cloud"
      period  = "60s"
      regions = ["EUROPE", "ASIA_PACIFIC", "SOUTH_AMERICA", "USA_IOWA"]
      path    = "/api/task_manager/_health"
    }
  }

  notification = {
    display_name = "Discord"
    type         = "pubsub"
    labels = {
      topic : "${module.pubsub.id}"
      #fallback_channel : true # The id of this channel will be included in the "fallback_channels_ids" output.type = "pubsub" }
    }
  }
  topic_name = "uptime-notification"
  file_name  = "uptime-notification.zip"
}

module "uptime-check" {
  for_each = local.uptime
  source   = "terraform-google-modules/cloud-operations/google//modules/simple-uptime-check"
  version  = "~> 0.4"

  project_id                = var.project
  uptime_check_display_name = "${each.key} uptime check"
  protocol                  = "HTTPS"
  period                    = each.value.period
  selected_regions          = each.value.regions
  path                      = each.value.path
  timeout                   = "60s"
  auth_info = {
    username = "remote_monitoring_agent"
    password = var.eck_rmon_password
  }

  monitored_resource = {
    monitored_resource_type = "uptime_url"
    labels = {
      "project_id" = var.project
      "host"       = each.value.host
    }
  }

  accepted_response_status_classes = ["STATUS_CLASS_2XX"]

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

resource "google_storage_bucket_object" "source" {
  name   = "function-uptime-notification-${data.archive_file.main.output_sha}.zip"
  bucket = var.gcf_bucket
  source = "${path.module}/${local.file_name}"
}

resource "google_cloudfunctions2_function" "uptime" {
  name        = "gcp-uptime-discord-notification"
  location    = var.region
  description = "Discord gcp monitoring notification"

  build_config {
    runtime           = "python312"
    entry_point       = "pubsub_event"
    docker_repository = "projects/${var.project}/locations/${var.region}/repositories/gcf-artifacts"
    source {
      storage_source {
        bucket = var.gcf_bucket
        object = google_storage_bucket_object.source.name
      }
    }
  }

  service_config {
    max_instance_count             = 3
    available_memory               = "128Mi"
    timeout_seconds                = 60
    ingress_settings               = "ALLOW_INTERNAL_ONLY"
    all_traffic_on_latest_revision = true
    environment_variables = {
      WEBHOOK_URL = var.discord_webhook
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    service_account_email = null
    pubsub_topic          = module.pubsub.id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    # retry_policy   = "RETRY_POLICY_RETRY"
  }
}

data "archive_file" "main" {
  type = "zip"

  source {
    content  = file("${path.module}/function-source/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/function-source/requirements.txt")
    filename = "requirements.txt"
  }
  output_path = "${path.module}/${local.file_name}"
}



