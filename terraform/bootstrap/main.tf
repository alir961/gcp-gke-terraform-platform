terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.vpc_name}-subnet"
  ip_cidr_range = var.cidr_block
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_storage_bucket" "image_bucket" {
  name     = var.bucket_name
  location = "EUROPE-WEST1"
}
