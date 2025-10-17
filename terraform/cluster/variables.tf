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

variable "machine_type" {
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "bucket_name" {
  description = "GCS bucket where the bootstrap Terraform state is stored"
  type        = string
}

variable "prefix" {
  description = "Prefix (folder) of the bootstrap Terraform state in the bucket"
  type        = string
}
