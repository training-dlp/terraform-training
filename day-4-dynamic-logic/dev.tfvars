environment       = "dev"
location          = "centralus"
enable_monitoring = false
enable_backup     = false

container_names = ["dev-test-data"]

scaling_rules = [
  {
    name           = "dev-cpu-rule"
    metric_name    = "cpu"
    metric_trigger = 90
  }
]

environment_variables = {
  "DEBUG"     = "true"
  "LOG_LEVEL" = "debug"
}
