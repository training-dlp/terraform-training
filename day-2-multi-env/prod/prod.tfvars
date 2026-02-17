project_name = "tfworkshop"
environment  = "prod"
location     = "eastus"

# Production: Full resources for production workloads
container_cpu    = 1.0
container_memory = "2Gi"
min_replicas     = 3
max_replicas     = 10

storage_account_tier     = "Premium"
storage_replication_type = "GRS"

log_retention_days = 90

tags = {
  CostCenter  = "Production"
  Owner       = "OpsTeam"
  Criticality = "High"
}
