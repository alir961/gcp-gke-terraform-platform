variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "zone" {
  description = "GCP zone where the cluster will be created"
  type        = string
}

variable "vpc_network_id" {
  description = "The ID of the existing VPC network to attach the cluster to"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the existing subnet for the cluster"
  type        = string
}

variable "node_count" {
  description = "Number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "bucket_name" {
  description = "GCS bucket for storing Terraform state"
  type        = string
}

variable "prefix" {
  description = "Prefix for storing Terraform state in GCS"
  type        = string
}