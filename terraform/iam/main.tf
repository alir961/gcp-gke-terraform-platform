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
      for identity_type, principals in var.members : [
        for principal, roles in principals : [
          for role in roles : {
            principal = principal
            type      = identity_type
            role      = role
          }
        ]
      ]
    ]) : "${item.type}-${item.principal}-${item.role}" => item
  }
}

resource "google_project_iam_member" "members" {
  for_each = local.iam_bindings
  project  = var.project_id
  role     = each.value.role
  member   = "${each.value.type}:${each.value.principal}"
}

resource "google_billing_account_iam_member" "billing" {
  billing_account_id = var.billing_account_id
  role               = "roles/billing.viewer"
  member             = "user:${var.professor}"
}
