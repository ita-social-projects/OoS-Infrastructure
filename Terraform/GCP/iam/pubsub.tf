resource "google_pubsub_topic_iam_member" "member" {
  project = var.project
  topic   = var.pubsub_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project}@gcp-sa-monitoring-notification.iam.gserviceaccount.com"
}