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