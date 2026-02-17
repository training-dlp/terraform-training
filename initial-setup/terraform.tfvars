# Terraform Workshop - Initial Setup Configuration

project_name = "tfworkshop"
location     = "eastus"
environment  = "initial"

# Container App Configuration
container_app_cpu    = 0.25
container_app_memory = "0.5Gi"
min_replicas         = 1
max_replicas         = 3

# Additional Tags
tags = {
  Owner       = "Workshop-Team"
  CostCenter  = "Training"
  Department  = "Engineering"
}
