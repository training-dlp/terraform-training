project_name = "tfworkshop"
environment  = "staging"
location     = "eastus"

# Staging: Medium resources for realistic testing
container_cpu    = 0.5
container_memory = "1Gi"
min_replicas     = 2
max_replicas     = 4

storage_account_tier     = "Standard"
storage_replication_type = "GRS"

log_retention_days = 60

tags = {
  CostCenter = "QA"
  Owner      = "QATeam"
}
