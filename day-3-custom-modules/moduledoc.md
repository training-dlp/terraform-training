# Azure Container Apps Terraform Module

A comprehensive, production-ready Terraform module for deploying Azure Container Apps with full configuration support.

## Features

- ✅ Container App Environment creation or use existing
- ✅ Multiple container support
- ✅ Advanced scaling rules (HTTP, TCP, custom)
- ✅ Ingress configuration with traffic splitting
- ✅ Health probes (liveness, readiness, startup)
- ✅ Volume mounting support
- ✅ Dapr integration
- ✅ Managed identity support
- ✅ Private container registry integration
- ✅ Secret management
- ✅ Custom domains and certificates
- ✅ IP security restrictions
- ✅ Zone redundancy support

## Requirements

- Terraform >= 1.0
- Azure Provider >= 3.0

## Usage

### Basic Example

```hcl
module "container_app" {
  source = "./path-to-module"

  resource_group_name = "myapp-rg"
  location            = "eastus"
  environment_name    = "myapp-env"
  container_app_name  = "myapp"

  containers = [
    {
      name   = "main"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  ]

  ingress = {
    target_port      = 80
    external_enabled = true
  }

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}
```

### Advanced Example with Scaling

```hcl
module "container_app" {
  source = "./path-to-module"

  resource_group_name          = "myapp-rg"
  location                     = "eastus"
  environment_name             = "myapp-env"
  container_app_name           = "myapp-api"
  log_analytics_workspace_id   = azurerm_log_analytics_workspace.main.id
  
  min_replicas = 2
  max_replicas = 20

  containers = [
    {
      name   = "api"
      image  = "myregistry.azurecr.io/myapp:v1.0.0"
      cpu    = 0.5
      memory = "1Gi"
      
      env = [
        {
          name  = "ASPNETCORE_ENVIRONMENT"
          value = "Production"
        },
        {
          name        = "ConnectionString"
          secret_name = "db-connection-string"
        }
      ]

      readiness_probe = {
        transport    = "HTTP"
        port         = 8080
        path         = "/health/ready"
        interval_seconds = 10
        timeout          = 3
        failure_count_threshold = 3
      }

      liveness_probe = {
        transport    = "HTTP"
        port         = 8080
        path         = "/health/live"
        initial_delay = 5
        interval_seconds = 30
      }
    }
  ]

  ingress = {
    target_port      = 8080
    external_enabled = true
    transport        = "http"
    
    traffic_weight = [
      {
        latest_revision = true
        percentage      = 100
      }
    ]
  }

  http_scale_rules = [
    {
      name                = "http-scaling"
      concurrent_requests = 100
    }
  ]

  registries = [
    {
      server               = "myregistry.azurecr.io"
      identity             = azurerm_user_assigned_identity.main.id
    }
  ]

  identity = {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.main.id]
  }

  secrets = [
    {
      name  = "db-connection-string"
      value = var.database_connection_string
    }
  ]

  tags = {
    Environment = "production"
    Application = "myapp-api"
  }
}
```

### Using Existing Environment

```hcl
module "container_app" {
  source = "./path-to-module"

  resource_group_name      = "myapp-rg"
  location                 = "eastus"
  container_app_name       = "myapp-worker"
  create_environment       = false
  existing_environment_id  = azurerm_container_app_environment.existing.id

  containers = [
    {
      name   = "worker"
      image  = "myapp/worker:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  ]
}
```

### Queue-Based Scaling with Azure Storage Queue

```hcl
module "container_app" {
  source = "./path-to-module"

  resource_group_name = "myapp-rg"
  location            = "eastus"
  environment_name    = "myapp-env"
  container_app_name  = "queue-processor"

  containers = [
    {
      name   = "processor"
      image  = "myapp/queue-processor:latest"
      cpu    = 0.25
      memory = "0.5Gi"
      
      env = [
        {
          name        = "STORAGE_CONNECTION_STRING"
          secret_name = "storage-connection"
        }
      ]
    }
  ]

  custom_scale_rules = [
    {
      name             = "queue-scaling"
      custom_rule_type = "azure-queue"
      metadata = {
        queueName   = "tasks"
        queueLength = "5"
      }
      authentication = [
        {
          secret_name       = "storage-connection"
          trigger_parameter = "connection"
        }
      ]
    }
  ]

  secrets = [
    {
      name  = "storage-connection"
      value = var.storage_connection_string
    }
  ]
}
```

### Multi-Container with Dapr

```hcl
module "container_app" {
  source = "./path-to-module"

  resource_group_name = "myapp-rg"
  location            = "eastus"
  environment_name    = "myapp-env"
  container_app_name  = "myapp-service"

  containers = [
    {
      name   = "app"
      image  = "myapp:latest"
      cpu    = 0.5
      memory = "1Gi"
      
      env = [
        {
          name  = "DAPR_HTTP_PORT"
          value = "3500"
        }
      ]
    }
  ]

  dapr = {
    app_id       = "myapp-service"
    app_port     = 8080
    app_protocol = "http"
  }

  ingress = {
    target_port      = 8080
    external_enabled = true
  }
}
```

### Private Container App with VNet Integration

```hcl
module "container_app" {
  source = "./path-to-module"

  resource_group_name             = "myapp-rg"
  location                        = "eastus"
  environment_name                = "myapp-env"
  container_app_name              = "private-app"
  infrastructure_subnet_id        = azurerm_subnet.container_apps.id
  internal_load_balancer_enabled  = true
  zone_redundancy_enabled         = true

  containers = [
    {
      name   = "app"
      image  = "myapp:latest"
      cpu    = 0.5
      memory = "1Gi"
    }
  ]

  ingress = {
    target_port      = 8080
    external_enabled = false  # Internal only
    
    ip_security_restrictions = [
      {
        name             = "corporate-network"
        ip_address_range = "10.0.0.0/8"
        action           = "Allow"
        description      = "Allow corporate network"
      }
    ]
  }
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| resource_group_name | Name of the resource group | `string` | n/a | yes |
| location | Azure region for resources | `string` | n/a | yes |
| environment_name | Name of the Container App Environment | `string` | n/a | yes |
| container_app_name | Name of the Container App | `string` | n/a | yes |
| containers | List of containers configuration | `list(object)` | n/a | yes |
| create_environment | Whether to create a new environment | `bool` | `true` | no |
| existing_environment_id | ID of existing environment | `string` | `null` | no |
| min_replicas | Minimum number of replicas | `number` | `1` | no |
| max_replicas | Maximum number of replicas | `number` | `10` | no |
| ingress | Ingress configuration | `object` | `null` | no |
| identity | Managed identity configuration | `object` | `null` | no |
| dapr | Dapr configuration | `object` | `null` | no |
| secrets | List of secrets | `list(object)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

See `variables.tf` for complete variable definitions.

## Outputs

| Name | Description |
|------|-------------|
| container_app_id | The ID of the Container App |
| container_app_name | The name of the Container App |
| container_app_fqdn | The FQDN of the Container App's ingress |
| container_app_latest_revision_name | The name of the latest revision |
| container_app_environment_id | The ID of the Container App Environment |
| identity_principal_id | The Principal ID of the managed identity |

See `outputs.tf` for complete output definitions.

## Container Configuration

### CPU and Memory

Container resources are specified as:
- CPU: decimal values (e.g., 0.25, 0.5, 1.0, 2.0)
- Memory: strings with units (e.g., "0.5Gi", "1Gi", "2Gi")

### Health Probes

Three types of health probes are supported:
- **Liveness Probe**: Determines if container is running
- **Readiness Probe**: Determines if container is ready for traffic
- **Startup Probe**: Protects slow-starting containers

Supported transports: `HTTP`, `TCP`

## Scaling

### HTTP Scaling
Scales based on concurrent HTTP requests:
```hcl
http_scale_rules = [
  {
    name                = "http-rule"
    concurrent_requests = 100
  }
]
```

### Custom Scaling
Supports various scalers including:
- Azure Service Bus Queue/Topic
- Azure Storage Queue
- Azure Event Hubs
- Kafka
- RabbitMQ
- Redis
- And many more via KEDA

### TCP Scaling
Scales based on concurrent TCP connections.

## Security

### Secrets Management
Secrets are encrypted and can be referenced in environment variables:
```hcl
secrets = [
  {
    name  = "my-secret"
    value = var.secret_value
  }
]

# Reference in container env
env = [
  {
    name        = "SECRET_VALUE"
    secret_name = "my-secret"
  }
]
```

### IP Restrictions
Limit access to specific IP ranges:
```hcl
ingress = {
  target_port = 80
  ip_security_restrictions = [
    {
      name             = "office"
      ip_address_range = "203.0.113.0/24"
      action           = "Allow"
    }
  ]
}
```

## Traffic Management

### Traffic Splitting
Support for blue-green and canary deployments:
```hcl
ingress = {
  target_port = 80
  traffic_weight = [
    {
      revision_suffix = "blue"
      percentage      = 80
    },
    {
      revision_suffix = "green"
      percentage      = 20
    }
  ]
}
```

## Best Practices

1. **Always use health probes** for production workloads
2. **Enable zone redundancy** for high availability
3. **Use managed identities** instead of username/password for registries
4. **Store sensitive data in secrets**, not environment variables
5. **Set appropriate resource limits** (CPU/memory) to avoid over-provisioning
6. **Use Log Analytics** for monitoring and troubleshooting
7. **Tag all resources** for cost tracking and organization
8. **Enable auto-scaling** with appropriate rules for your workload

## License

MIT

## Authors

Created by [Your Organization]
