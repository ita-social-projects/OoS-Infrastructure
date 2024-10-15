
module "pubsub_kibana" {
  source              = "terraform-google-modules/pubsub/google"
  version             = "~> 6.0"
  project_id          = var.project
  topic               = local.topic_kibana
  grant_token_creator = false
  topic_labels = {
    name = "kibana-alerting"
  }
}

resource "google_storage_bucket_object" "kibana_source" {
  name   = "function-kibana-alerting-${data.archive_file.kibana.output_sha}.zip"
  bucket = var.gcf_bucket
  source = "${path.module}/${local.kibana_file_name}"
}

resource "google_cloudfunctions2_function" "kibana" {
  name        = "gcp-kibana-discord-notification"
  location    = var.region
  description = "Kibana alerting to Discord webhook"

  build_config {
    runtime           = "python312"
    entry_point       = "pubsub_event"
    docker_repository = "projects/${var.project}/locations/${var.region}/repositories/gcf-artifacts"
    source {
      storage_source {
        bucket = var.gcf_bucket
        object = google_storage_bucket_object.kibana_source.name
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
      WEBHOOK_URL      = var.discord_kibana_webhook
      LOG_EXECUTION_ID = "true"
    }
  }

  event_trigger {
    trigger_region        = var.region
    event_type            = "google.cloud.pubsub.topic.v1.messagePublished"
    service_account_email = null
    pubsub_topic          = module.pubsub_kibana.id
    retry_policy          = "RETRY_POLICY_DO_NOT_RETRY"
    # retry_policy   = "RETRY_POLICY_RETRY"
  }
}

data "archive_file" "kibana" {
  type = "zip"

  source {
    content  = file("${path.module}/function-kibana/main.py")
    filename = "main.py"
  }
  source {
    content  = file("${path.module}/function-kibana/requirements.txt")
    filename = "requirements.txt"
  }
  output_path = "${path.module}/${local.kibana_file_name}"
}

