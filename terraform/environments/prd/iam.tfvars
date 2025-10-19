project_id         = "example-project-prd"
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
    ]
    "member-3@example.com" = [
      "roles/viewer",
      "roles/container.admin",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
    ]
    "member-2@example.com" = [
      "roles/viewer",
      "roles/container.admin",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
    ]
    "member-1@example.com" = [
      "roles/viewer",
      "roles/container.admin",
      "roles/artifactregistry.writer",
      "roles/cloudsql.admin",
    ]
    "teacher@example.com" = [
      "roles/viewer",
      "roles/iam.securityReviewer",
    ]
  }
  serviceAccount = {}
}
