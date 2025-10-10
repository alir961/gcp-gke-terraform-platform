terraform {
  backend "gcs" {
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_iam_member" "members" {
  for_each = var.members
  project  = var.project_id
  role     = each.value
  member   = "user:${each.key}"
}

resource "google_billing_account_iam_member" "billing" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.viewer"
  member             = "user:${var.professor}"
}

resource "google_project_iam_member" "iam_reader" {
  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  = "user:${var.professor}"
}
