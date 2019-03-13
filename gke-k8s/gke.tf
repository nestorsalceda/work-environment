provider "google" {}

resource "google_container_cluster" "sysdig_work" {
  name               = "sysdig-work"
  initial_node_count = 3

  node_config {
    image_type = "ubuntu"

    # Uncomment next line if you need more HP
    # machine_type = "n1-standard-2"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  network_policy {
    enabled = true
  }

  provisioner "local-exec" {
    command = "./configure_kubectl"
  }
}
