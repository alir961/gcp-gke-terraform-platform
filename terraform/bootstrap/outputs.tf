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
  value       = google_storage_bucket.state_bucket.name
  description = "The name of the created storage bucket"
}
output "image_repository" {
  value       = "${google_artifact_registry_repository.tasks.location}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.tasks.repository_id}/tasks-api"
  description = "Image path of the tasks API in Artifact Registry"
}
