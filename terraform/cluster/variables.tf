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
  description = "Optional override for the VPC network ID (defaults to bootstrap output)"
  type        = string
  default     = ""
}

variable "subnet_id" {
  description = "Optional override for the subnet ID (defaults to bootstrap output)"
  type        = string
  default     = ""
}

variable "remove_default_node_pool" {
  description = "Whether to remove the default node pool created with the cluster"
  type        = bool
  default     = false
}

variable "issue_client_certificate" {
  description = "Whether the cluster API should issue client certificates"
  type        = bool
  default     = false
}

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_count" {
  description = "Number of nodes in the managed node pool"
  type        = number
  default     = 1
}

variable "bucket_name" {
  description = "GCS bucket where the bootstrap Terraform state is stored"
  type        = string
}

variable "prefix" {
  description = "Prefix (folder) of the bootstrap Terraform state in the bucket"
  type        = string
}

variable "env" {
  description = "Environment (dev/prod)"
  type        = string
  default     = "dev"
}

variable "ingress_ip_name" {
  description = "Name of the global static IP reserved for the HTTP(S) load balancer"
  type        = string
}

variable "image_repository" {
  description = "Optional override for the API image repository (set by CI)"
  type        = string
  default     = ""
}

variable "image_tag" {
  description = "Immutable API image tag to deploy, e.g. the commit SHA (set by CI); empty keeps the values file"
  type        = string
  default     = ""
}
