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

# Holds the Terraform state of every module: keep old versions and never expose it.
resource "google_storage_bucket" "state_bucket" {
  name                        = var.bucket_name
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }
}

moved {
  from = google_storage_bucket.image_bucket
  to   = google_storage_bucket.state_bucket
}

resource "google_project_service" "artifact_registry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Docker images of the tasks API, pushed by CI and pulled by the GKE nodes.
resource "google_artifact_registry_repository" "tasks" {
  location      = var.region
  repository_id = "tasks-registry"
  format        = "DOCKER"
  description   = "tasks-api container images"

  cleanup_policies {
    id     = "keep-recent"
    action = "KEEP"
    most_recent_versions {
      keep_count = 20
    }
  }

  cleanup_policies {
    id     = "delete-old"
    action = "DELETE"
    condition {
      older_than = "2592000s" # 30 days
    }
  }

  depends_on = [google_project_service.artifact_registry]
}
