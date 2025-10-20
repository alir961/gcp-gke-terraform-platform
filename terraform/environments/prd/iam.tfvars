project_id         = "example-project-prd"
region             = "europe-west1"
professor          = "teacher@example.com"
billing_account_id = "XXXXXX-XXXXXX-XXXXXX"

members = {
  user = {
    "member-4@example.com" = [
      "roles/owner",
    ]
    "member-3@example.com" = [
      "roles/owner",
    ]
    "member-2@example.com" = [
      "roles/owner",
    ]
    "member-1@example.com" = [
      "roles/owner",
    ]
    "teacher@example.com" = [
      "roles/viewer",
      "roles/billing.viewer",
      "roles/iam.securityReviewer",
      "roles/compute.viewer",
      "roles/container.viewer",
      "roles/dns.reader",
      "roles/logging.viewer",
      "roles/monitoring.viewer",
    ]
  }
  serviceAccount = {
    "github-actions-sa@example-project-prd.iam.gserviceaccount.com" = [
      "roles/billing.admin",
      "roles/cloudsql.admin",
      "roles/compute.networkAdmin",
      "roles/container.admin",
      "roles/dns.admin",
      "roles/resourcemanager.projectIamAdmin",
      "roles/secretmanager.admin",
      "roles/servicenetworking.networksAdmin",
      "roles/storage.admin",
    ]
  }
}
