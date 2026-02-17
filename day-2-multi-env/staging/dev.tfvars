project_name = "tfworkshop"
environment  = "dev"
location     = "eastus"

# Dev-specific: Minimal resources for cost optimization
container_cpu    = 0.25
container_memory = "0.5Gi"
min_replicas     = 1
max_replicas     = 2

storage_account_tier     = "Standard"
storage_replication_type = "LRS"

log_retention_days = 30

tags = {
  CostCenter = "Development"
  Owner      = "DevTeam"
}
