terraform {
  backend "gcs" {
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  iam_bindings = {
    for item in flatten([
      for user, roles in var.members : [
        for role in roles : {
          user = user
          role = role
        }
      ]
    ]) : "${item.user}-${item.role}" => item
  }
}

resource "google_project_iam_member" "members" {
  for_each = local.iam_bindings
  project  = var.project_id
  role     = each.value.role
  member   = "user:${each.value.user}"
}

resource "google_billing_account_iam_member" "billing" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.viewer"
  member             = "user:${var.professor}"
}
