terraform {
  backend "gcs" {
  }
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
  location = "EU"
}

output "vpc_name" {
  value       = google_compute_network.vpc_network.name
  description = "The name of the created VPC"
}

output "subnet_id" {
  value       = google_compute_subnetwork.subnet.id
  description = "The ID of the created subnet"
}

output "vpc_id" {
  value       = google_compute_network.vpc_network.id
  description = "The ID of the created VPC"
}

output "bucket_name" {
  value       = google_storage_bucket.image_bucket.name
  description = "The name of the created storage bucket"
}