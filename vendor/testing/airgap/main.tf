terraform {
  backend "gcs" {
    bucket  = "replicated-customer-success"
    prefix  = "terraform/state"
  }
}

provider "google" {
  project = "smart-proxy-839"
  region  = "us-east4"
}

resource "google_compute_instance" "airgap_instance" {
  name         = "airgapped-instance"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = var.image_type
    }
  }

  network_interface {
    network = google_compute_network.embedded_airgap_network.self_link
    access_config {
    }
  }
}

resource "google_compute_network" "embedded_airgap_network" {
  name                    = "embedded-airgap-network"
  auto_create_subnetworks = "true"
}

output "application" {
  value = var.application_slug
}