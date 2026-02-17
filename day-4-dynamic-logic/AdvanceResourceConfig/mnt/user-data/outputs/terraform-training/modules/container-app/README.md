# Container App Terraform Module

A reusable Terraform module for deploying Azure Container Apps with comprehensive configuration options.

## Features

- ✅ Flexible resource sizing (CPU and memory)
- ✅ Auto-scaling with configurable min/max replicas
- ✅ HTTP-based scaling rules
- ✅ Health probes (liveness and readiness)
- ✅ Environment variables and secrets management
- ✅ Private container registry support
- ✅ Dapr integration
- ✅ Single or Multiple revision modes
- ✅ External or internal ingress
- ✅ Input validation
- ✅ Comprehensive outputs

## Usage

### Basic Example

```hcl
module "simple_app" {
  source = "./modules/container-app"
  
  name                         = "my-app"
  resource_group_name          = "rg-apps"
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "nginx:alpine"
  cpu             = 0.5
  memory          = "1Gi"
  
  min_replicas = 1
  max_replicas = 5
}
```

### Advanced Example with Secrets and Environment Variables

```hcl
module "advanced_app" {
  source = "./modules/container-app"
  
  name                         = "api-service"
  resource_group_name          = "rg-apps"
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "myregistry.azurecr.io/api:v1.0.0"
  cpu             = 1.0
  memory          = "2Gi"
  
  min_replicas = 2
  max_replicas = 10
  
  # Registry credentials
  registry_server   = "myregistry.azurecr.io"
  registry_username = "myregistry"
  registry_password = var.acr_password
  
  # Environment variables
  environment_variables = {
    "APP_ENV" = {
      name  = "APP_ENV"
      value = "production"
    }
    "LOG_LEVEL" = {
      name  = "LOG_LEVEL"
      value = "INFO"
    }
    "DB_CONNECTION" = {
      name        = "DB_CONNECTION"
      secret_name = "db-connection-string"
    }
  }
  
  # Secrets
  secrets = {
    "db-connection" = {
      name  = "db-connection-string"
      value = var.database_connection_string
    }
    "api-key" = {
      name  = "api-key"
      value = var.api_key
    }
  }
  
  # Health checks
  enable_health_probes = true
  health_check_path    = "/api/health"
  
  # Scaling
  enable_http_scale_rule    = true
  http_concurrent_requests  = 20
  
  tags = {
    Environment = "Production"
    Team        = "Platform"
  }
}
```

### Dapr-Enabled Microservice

```hcl
module "orders_service" {
  source = "./modules/container-app"
  
  name                         = "orders-service"
  resource_group_name          = "rg-microservices"
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "myregistry.azurecr.io/orders:latest"
  
  # Enable Dapr
  dapr_enabled = true
  dapr_app_id  = "orders-service"
  dapr_app_port = 3000
  
  environment_variables = {
    "STATE_STORE" = {
      name  = "STATE_STORE"
      value = "statestore"
    }
    "PUBSUB" = {
      name  = "PUBSUB"
      value = "pubsub"
    }
  }
}
```

### Internal Service (No External Ingress)

```hcl
module "worker_service" {
  source = "./modules/container-app"
  
  name                         = "background-worker"
  resource_group_name          = "rg-apps"
  container_app_environment_id = azurerm_container_app_environment.main.id
  
  container_image = "myworker:latest"
  
  # Internal only - no external access
  ingress_enabled  = false
  
  min_replicas = 1
  max_replicas = 3
  
  environment_variables = {
    "QUEUE_URL" = {
      name  = "QUEUE_URL"
      value = "https://queue.service.local"
    }
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | ~> 3.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| name | Name of the container app (2-32 chars, lowercase alphanumeric with hyphens) | `string` | n/a | yes |
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| container_app_environment_id | ID of the Container App Environment | `string` | n/a | yes |
| container_image | Container image to deploy | `string` | `"mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"` | no |
| container_name | Name of the container | `string` | `"main"` | no |
| cpu | CPU cores (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0) | `number` | `0.5` | no |
| memory | Memory allocation (e.g., '0.5Gi', '1Gi', '2Gi') | `string` | `"1Gi"` | no |
| min_replicas | Minimum number of replicas (0-30) | `number` | `1` | no |
| max_replicas | Maximum number of replicas (1-30) | `number` | `10` | no |
| revision_mode | Revision mode: 'Single' or 'Multiple' | `string` | `"Single"` | no |
| ingress_enabled | Enable ingress for the container app | `bool` | `true` | no |
| external_enabled | Enable external ingress | `bool` | `true` | no |
| target_port | Target port for ingress traffic | `number` | `80` | no |
| environment_variables | Environment variables for the container | `map(object)` | `{}` | no |
| secrets | Secrets for the container app | `map(object)` | `{}` | no |
| registry_server | Container registry server | `string` | `""` | no |
| registry_username | Container registry username | `string` | `""` | no |
| registry_password | Container registry password | `string` | `""` | no |
| dapr_enabled | Enable Dapr for the container app | `bool` | `false` | no |
| dapr_app_id | Dapr application ID | `string` | `""` | no |
| dapr_app_port | Port that Dapr will proxy traffic to | `number` | `3000` | no |
| enable_http_scale_rule | Enable HTTP-based scaling rule | `bool` | `true` | no |
| http_concurrent_requests | Concurrent requests for HTTP scaling | `number` | `10` | no |
| health_check_path | Path for health checks | `string` | `"/health"` | no |
| enable_health_probes | Enable liveness and readiness probes | `bool` | `true` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Container App |
| name | The name of the Container App |
| fqdn | The FQDN of the Container App's ingress |
| url | The full URL of the Container App |
| latest_revision_name | The name of the latest revision |
| latest_revision_fqdn | The FQDN of the latest revision |
| outbound_ip_addresses | List of outbound IP addresses |
| custom_domain_verification_id | ID for custom domain verification |
| configuration | Configuration summary object |

## Input Validation

This module includes comprehensive input validation:

- **Name**: Must be 2-32 characters, lowercase alphanumeric with hyphens, start/end with alphanumeric
- **CPU**: Must be one of the supported values (0.25 to 2.0 in 0.25 increments)
- **Memory**: Must be in format like '0.5Gi', '1Gi', '2Gi'
- **Replicas**: Min (0-30), Max (1-30), Max >= Min
- **Revision Mode**: Must be 'Single' or 'Multiple'
- **Target Port**: Must be between 1 and 65535
- **Dapr**: If enabled, app_id is required

## Best Practices

1. **Always use health probes** in production environments
2. **Store secrets securely** - never commit secrets to version control
3. **Use private registries** for custom images
4. **Configure appropriate resource limits** based on application needs
5. **Enable HTTP scaling** for web applications
6. **Use tags** for cost tracking and resource management
7. **Test in non-production** before deploying to production

## Examples Directory

See the `/examples` directory for complete working examples:
- `examples/simple/` - Basic container app deployment
- `examples/advanced/` - Full-featured production setup
- `examples/dapr/` - Dapr-enabled microservices
- `examples/multi-container/` - Multiple container apps

## License

MIT

## Authors

DevOps Training Team

## Version History

- **1.0.0** (2026-02-16): Initial release
  - Basic container app support
  - Input validation
  - Health probes
  - Secrets management
  - Dapr support
