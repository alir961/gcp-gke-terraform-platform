terraform {
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
}

locals {
  fqdn                 = "${trim(var.record_name, ".")}."
  bucket_domain_suffix = ".storage.googleapis.com"
  website_bucket_name  = var.static_site_bucket_name != "" ? var.static_site_bucket_name : replace(local.fqdn, ".", "-")
}

data "google_compute_global_address" "ingress" {
  project = var.project_id
  name    = var.ingress_ip_name
}

resource "google_dns_record_set" "ingress" {
  name         = local.fqdn
  managed_zone = var.dns_managed_zone
  type         = var.record_type
  ttl          = var.ttl
  rrdatas      = [data.google_compute_global_address.ingress.address]
}

resource "google_storage_bucket" "static_site" {
  count = var.create_static_site ? 1 : 0

  name                        = local.website_bucket_name
  location                    = var.bucket_location
  uniform_bucket_level_access = true
  project                     = var.project_id

  website {
    main_page_suffix = var.website_main_page
    not_found_page   = var.website_not_found_page
  }
}

resource "google_storage_bucket_iam_binding" "static_site_public" {
  count  = var.create_static_site ? 1 : 0
  bucket = google_storage_bucket.static_site[0].name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers",
  ]
}

locals {
  website_index = <<-EOT
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <title>IAC Group Project</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 40px; background: #0e1a2b; color: #f1f5f9; }
        main { max-width: 720px; margin: auto; }
        h1 { color: #38bdf8; }
        a { color: #f97316; }
        code { background: rgba(148, 163, 184, 0.2); padding: 4px 6px; border-radius: 4px; }
      </style>
    </head>
    <body>
      <main>
        <h1>API Tasks - Infrastructure as Code</h1>
        <p>Bienvenue sur le domaine public du projet. Les routes HTTP sont servies via <strong>GKE + Ingress HTTPS</strong>.</p>
        <p>API : <a href="${var.api_http_endpoint}" target="_blank">${var.api_http_endpoint}</a></p>
        <p>Monitoring (Grafana) : port-forward via <code>scripts/k8r.sh grafana</code>.</p>
        <p>Déploiement géré par Terraform + GitHub Actions (Plan/Apply automatiques).</p>
      </main>
    </body>
    </html>
  EOT

  website_404 = <<-EOT
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8" />
      <title>Not Found</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 40px; background: #111827; color: #e5e7eb; text-align: center; }
        a { color: #60a5fa; }
      </style>
    </head>
    <body>
      <h1>404 - Page not found</h1>
      <p>Revenez à l'API : <a href="${var.api_http_endpoint}">${var.api_http_endpoint}</a></p>
    </body>
    </html>
  EOT
}

resource "google_storage_bucket_object" "static_site_index" {
  count        = var.create_static_site ? 1 : 0
  name         = var.website_main_page
  bucket       = google_storage_bucket.static_site[0].name
  content      = local.website_index
  content_type = "text/html"
}

resource "google_storage_bucket_object" "static_site_404" {
  count        = var.create_static_site ? 1 : 0
  name         = var.website_not_found_page
  bucket       = google_storage_bucket.static_site[0].name
  content      = local.website_404
  content_type = "text/html"
}

output "record_name" {
  value = google_dns_record_set.ingress.name
}

output "static_site_url" {
  value       = var.create_static_site ? "https://${google_storage_bucket.static_site[0].name}${local.bucket_domain_suffix}" : null
  description = "Public URL of the static site bucket (if created)"
}
