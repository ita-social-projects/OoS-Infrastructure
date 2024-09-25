data "google_compute_image" "ubuntu" {
  name = "ubuntu-2204-jammy-v20240904"
  # family = "ubuntu-2204-lts"
  # TODO: Extract to variable
  project = "ubuntu-os-cloud"
}
