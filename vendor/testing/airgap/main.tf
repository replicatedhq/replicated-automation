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

# Download license file manually for first pass
# single jumpbox for both airgapped instance and existing cluster
# teardown only embedded airgapped node and namespace of existing cluster

### JUMPBOX INSTANCE
resource "google_compute_instance" "jumpbox_instance" {
  name                      = "jumpbox-instance"
  zone                      = var.zone
  machine_type              = var.machine_type
  allow_stopping_for_update = true

  boot_disk {
    auto_delete = var.disk_auto_delete

    initialize_params {
      image = var.image_type
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    #network = google_compute_network.embedded_airgap_network.self_link
    network = "default"
    access_config {
    }
  }

  provisioner "file" {
    source      = "scripts/jumpbox_download.sh"
    destination = "/tmp/jumpbox_download.sh"
  }

  provisioner "file" {
    source      = "scripts/jumpbox_upload.sh"
    destination = "/tmp/jumpbox_upload.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/jumpbox_download.sh",
      "/tmp/jumpbox_download.sh 'Hello' ",
      "chmod +x /tmp/jumpbox_upload.sh",
      "/tmp/jumpbox_upload.sh 'Hello' ",
    ]
  }
}

### AIRGAP INSTANCE
resource "google_compute_instance" "airgap_instance" {
  name                      = "airgap-instance"
  zone                      = var.zone
  machine_type              = var.machine_type
  allow_stopping_for_update = true

  boot_disk {
    auto_delete = var.disk_auto_delete

    initialize_params {
      image = var.image_type
      size  = var.disk_size_gb
      type  = var.disk_type
    }
  }

  network_interface {
    #network = google_compute_network.embedded_airgap_network.self_link
    network = "default"
    access_config {
    }
  }

  provisioner "file" {
    source      = "scripts/script1.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/script.sh",
      "/tmp/script.sh args",
    ]
  }
}

resource "google_compute_network" "embedded_airgap_network" {
  name                    = "embedded-airgap-network"
  auto_create_subnetworks = "true"
}

output "application" {
  value = var.application_slug
}