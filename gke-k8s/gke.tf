resource "google_container_cluster" "nestor_sysdig_work" {
  name               = "nestor-sysdig-work"
  initial_node_count = 2

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

  ip_allocation_policy {
    use_ip_aliases = true
  }

  monitoring_service = "none"
  logging_service = "none"

  provisioner "local-exec" {
    command = "./configure_kubectl"
  }
}
