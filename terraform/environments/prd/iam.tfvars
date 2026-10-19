project_id         = "example-project-prd"
region             = "europe-west1"
professor          = "teacher@example.com"
billing_account_id = "XXXXXX-XXXXXX-XXXXXX"

members = {
  user = {
    "member-4@example.com" = [
      "roles/editor",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/container.admin",
      "roles/dns.admin",
      "roles/logging.admin",
      "roles/monitoring.admin",
      "roles/secretmanager.admin",
      "roles/storage.admin",
    ]
    "member-3@example.com" = [
      "roles/editor",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/container.admin",
      "roles/dns.admin",
      "roles/logging.admin",
      "roles/monitoring.admin",
      "roles/secretmanager.admin",
      "roles/storage.admin",
    ]
    "member-2@example.com" = [
      "roles/editor",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/container.admin",
      "roles/dns.admin",
      "roles/logging.admin",
      "roles/monitoring.admin",
      "roles/secretmanager.admin",
      "roles/storage.admin",
    ]
    "member-1@example.com" = [
      "roles/editor",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/container.admin",
      "roles/dns.admin",
      "roles/logging.admin",
      "roles/monitoring.admin",
      "roles/secretmanager.admin",
      "roles/storage.admin",
    ]
    "teacher@example.com" = [
      "roles/viewer",
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
      "roles/cloudsql.admin",
      "roles/compute.networkAdmin",
      "roles/container.admin",
      "roles/dns.admin",
      "roles/iam.serviceAccountAdmin",
      "roles/iam.serviceAccountUser",
      "roles/resourcemanager.projectIamAdmin",
      "roles/secretmanager.admin",
      "roles/servicenetworking.networksAdmin",
      "roles/storage.admin",
    ]
    "github-actions-sa@example-project-dev.iam.gserviceaccount.com" = [
      "roles/dns.admin",
    ]
    "github-actions-ci-cd@example-project-dev.iam.gserviceaccount.com" = [
      "roles/dns.admin",
    ]
  }
}
