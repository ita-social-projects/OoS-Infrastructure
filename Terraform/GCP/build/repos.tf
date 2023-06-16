resource "google_cloudbuildv2_repository" "backend" {
  provider          = google-beta
  name              = "OoS-Backend"
  parent_connection = "projects/${var.project}/locations/${var.region}/connections/Github"
  remote_uri        = "https://github.com/ita-social-projects/OoS-Backend.git"
}

resource "google_cloudbuildv2_repository" "frontend" {
  provider          = google-beta
  name              = "OoS-Frontend"
  parent_connection = "projects/${var.project}/locations/${var.region}/connections/Github"
  remote_uri        = "https://github.com/ita-social-projects/OoS-Frontend.git"
}
