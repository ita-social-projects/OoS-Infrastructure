# TODO: For some time bucket will not be 'public'.
#       Will uncomment or remove the code when we have final solution.
resource "google_storage_bucket_iam_member" "public_read" {
  bucket = var.bucket
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

# resource "google_storage_bucket_iam_member" "group-admin" {
#   bucket = var.bucket
#   role   = "roles/storage.objectAdmin"
#   member = "group:${var.access_group_email}"
#   count  = "${var.access_group_email}" != "none" ? 1 : 0
# }

resource "google_storage_bucket_iam_member" "webapi_admin" {
  bucket = var.bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.app.email}"
}
