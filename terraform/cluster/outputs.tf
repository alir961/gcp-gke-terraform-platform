output "cluster_name" {
  value = google_container_cluster.tasks_cluster.name
}

output "ingress_ip_address" {
  value = google_compute_global_address.ingress_ip.address
}

output "ingress_ip_name" {
  value = google_compute_global_address.ingress_ip.name
}
