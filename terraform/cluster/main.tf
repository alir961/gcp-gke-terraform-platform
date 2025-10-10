terraform {
  backend "gcs"{
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_container_cluster" "tasks_cluster" {
  name     = "tasks-cluster"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = var.vpc_network_id
  subnetwork = var.subnet_id
}

resource "google_container_node_pool" "tasks_nodes" {
  name       = "tasks-node-pool"
  cluster    = google_container_cluster.tasks_cluster.name
  location   = google_container_cluster.tasks_cluster.location
  node_count = var.node_count

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
