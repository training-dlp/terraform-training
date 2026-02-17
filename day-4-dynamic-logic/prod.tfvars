environment       = "prod"
location          = "eastus"
enable_monitoring = true
enable_backup     = true

# List of strings for storage containers
container_names = [
  "customer-data",
  "audit-logs",
  "archive-backups"
]

# List of objects for scaling rules
scaling_rules = [
  {
    name           = "high-cpu-autoscale"
    metric_name    = "cpu"
    metric_trigger = 70
  },
  {
    name           = "memory-pressure-scale"
    metric_name    = "memory"
    metric_trigger = 85
  }
]

# Map of strings for environment variables
environment_variables = {
  "NODE_ENV"     = "production"
  "API_ENDPOINT" = "https://api.myapp.com"
  "DB_TIMEOUT"   = "30s"
}

