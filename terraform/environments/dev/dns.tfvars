project_id           = "example-project-dev"
dns_managed_zone     = "example-project-com"
record_name          = "api.dev.example-project.com"
cluster_state_bucket = "example-project-dev-tfstate"
cluster_state_prefix = "cluster/dev"
ttl                  = 60
ingress_ip_name      = "tasks-ingress-ip-dev"
create_static_site   = false
