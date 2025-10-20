project_id         = "example-project-dev"
region             = "europe-west1"
professor          = "teacher@example.com"
billing_account_id = "XXXXXX-XXXXXX-XXXXXX"

members = {
  user = {
    "member-4@example.com" = [
      "roles/viewer",
      "roles/container.admin",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/dns.admin",
      "roles/storage.objectAdmin",
    ]
    "member-3@example.com" = [
      "roles/viewer",
      "roles/container.admin",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/dns.admin",
      "roles/storage.objectAdmin",
    ]
    "member-2@example.com" = [
      "roles/viewer",
      "roles/container.admin",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/dns.admin",
      "roles/storage.objectAdmin",
    ]
    "member-1@example.com" = [
      "roles/viewer",
      "roles/container.admin",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
      "roles/dns.admin",
      "roles/storage.objectAdmin",
    ]
    "teacher@example.com" = [
      "roles/viewer",
      "roles/iam.securityReviewer",
      "roles/compute.viewer",
      "roles/container.viewer",
      "roles/dns.admin",
    ]
  }
  serviceAccount = {
    "github-actions-sa@example-project-dev.iam.gserviceaccount.com" = [
      "roles/dns.admin",
      "roles/compute.networkAdmin",
      "roles/storage.objectAdmin",
    ]
    "github-actions-ci-cd@example-project-dev.iam.gserviceaccount.com" = [
      "roles/dns.admin",
      "roles/compute.networkAdmin",
      "roles/storage.objectAdmin",
    ]
  }
}
