terraform {
  backend "gcs" {
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

data "terraform_remote_state" "bootstrap" {
  backend = "gcs"

  config = {
    bucket = var.bucket_name
    prefix = var.prefix
  }
}

data "terraform_remote_state" "db" {
  backend = "gcs"

  config = {
    bucket = var.bucket_name
    prefix = local.db_state_prefix
  }
}

locals {
  vpc_network_id  = var.vpc_network_id != "" ? var.vpc_network_id : data.terraform_remote_state.bootstrap.outputs.vpc_id
  subnet_id       = var.subnet_id != "" ? var.subnet_id : data.terraform_remote_state.bootstrap.outputs.subnet_id
  db_state_prefix = replace(var.prefix, "bootstrap", "db")
}

resource "google_container_cluster" "tasks_cluster" {
  name     = "tasks-cluster"
  location = var.zone

  remove_default_node_pool = var.remove_default_node_pool
  initial_node_count       = 1

  network             = local.vpc_network_id
  subnetwork          = local.subnet_id
  deletion_protection = false

  master_auth {
    client_certificate_config {
      issue_client_certificate = var.issue_client_certificate
    }
  }
}

resource "google_container_node_pool" "tasks_nodes" {
  name     = "tasks-node-pool"
  cluster  = google_container_cluster.tasks_cluster.name
  location = google_container_cluster.tasks_cluster.location

  node_count = var.node_count

  autoscaling {
    min_node_count = 1
    max_node_count = 10
  }

  node_config {
    machine_type = var.machine_type
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

resource "google_compute_global_address" "ingress_ip" {
  name = var.ingress_ip_name
}
