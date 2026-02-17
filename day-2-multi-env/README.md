# Day 2: Multi-Environment Deployment

## Overview

Learn how to manage multiple environments (dev, staging, production) using Terraform workspaces, separate state files, and environment-specific configurations.

## Learning Objectives

- Understand environment separation strategies
- Use Terraform workspaces effectively
- Manage environment-specific variables
- Implement naming conventions across environments
- Deploy and manage multiple environments simultaneously

## Prerequisites

- Completed Day 1 (State Management)
- Remote state backend configured
- Understanding of Terraform variables

## Topics Covered

### 1. Environment Separation Strategies

**Strategy A: Workspaces** (Single Backend)
- Single codebase
- Multiple state files via workspaces
- Best for similar environments

**Strategy B: Separate Directories** (Multiple Backends)
- Directory per environment
- Isolated state files
- Best for divergent environments

**Strategy C: Separate Repositories**
- Complete isolation
- Different teams/policies
- Enterprise approach

### 2. Terraform Workspaces

```bash
# List workspaces
terraform workspace list

# Create workspace
terraform workspace new dev

# Switch workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete dev
```

### 3. Environment-Specific Configuration

Using variable files:
- `dev.tfvars`
- `staging.tfvars`
- `prod.tfvars`

### 4. Dynamic Naming and Tagging

## Architecture

```
Repository Structure
├── dev/
│   ├── backend.hcl
│   ├── dev.tfvars
│   └── terraform.tf → ../modules
├── staging/
│   ├── backend.hcl
│   ├── staging.tfvars
│   └── terraform.tf → ../modules
└── prod/
    ├── backend.hcl
    ├── prod.tfvars
    └── terraform.tf → ../modules

Remote State (Azure Storage)
├── dev-state.tfstate
├── staging-state.tfstate
└── prod-state.tfstate
```

## Exercises

### Exercise 1: Deploy Dev Environment (15 minutes)

```bash
cd day-2-multi-env/dev

# Initialize with dev backend
terraform init -backend-config=backend.hcl

# Plan with dev variables
terraform plan -var-file=dev.tfvars

# Apply
terraform apply -var-file=dev.tfvars
```

### Exercise 2: Deploy Staging Environment (15 minutes)

```bash
cd ../staging

# Initialize with staging backend
terraform init -backend-config=backend.hcl

# Deploy staging
terraform apply -var-file=staging.tfvars
```

### Exercise 3: Deploy Production Environment (20 minutes)

```bash
cd ../prod

# Initialize with prod backend
terraform init -backend-config=backend.hcl

# Review production configuration
terraform plan -var-file=prod.tfvars

# Deploy production (with approval)
terraform apply -var-file=prod.tfvars
```

### Exercise 4: Compare Environments (10 minutes)

```bash
# View all environments
az group list --query "[?tags.Workshop=='Terraform-Advanced'].{Name:name, Environment:tags.Environment}" -o table

# Compare configurations
diff dev/dev.tfvars staging/staging.tfvars
diff staging/staging.tfvars prod/prod.tfvars
```

## Environment Differences

### Dev Environment
- **Purpose**: Development and testing
- **Resources**: Minimal (1 replica, small compute)
- **Availability**: Standard
- **Monitoring**: Basic
- **Cost**: Optimized for development

### Staging Environment
- **Purpose**: Pre-production testing
- **Resources**: Medium (2 replicas, standard compute)
- **Availability**: Enhanced
- **Monitoring**: Full monitoring
- **Cost**: Similar to production

### Production Environment
- **Purpose**: Live production workloads
- **Resources**: Full (3+ replicas, premium compute)
- **Availability**: High availability
- **Monitoring**: Full monitoring + alerts
- **Cost**: Production-grade

## Variable Hierarchy

```hcl
Priority (highest to lowest):
1. Command line (-var)
2. *.auto.tfvars (alphabetical)
3. terraform.tfvars
4. environment variables (TF_VAR_*)
5. default values in variables.tf
```

## Naming Convention

```
Resource Pattern: {resource-type}-{project}-{environment}-{region}-{purpose}

Examples:
- rg-tfworkshop-dev-eastus
- ca-tfworkshop-prod-eastus-api
- st-tfworkshop-staging-eastus-data
```

## Best Practices

### 1. Environment Parity
Keep environments as similar as possible, varying only:
- Resource sizing
- Replica counts
- Monitoring levels
- Backup policies

### 2. Variable Management
```hcl
# ✅ Good: Use variable files
terraform apply -var-file=prod.tfvars

# ❌ Bad: Inline variables
terraform apply -var="environment=prod" -var="replicas=3"
```

### 3. State Isolation
```hcl
# ✅ Good: Separate state per environment
backend "azurerm" {
  key = "prod.tfstate"
}

# ❌ Bad: Shared state file
backend "azurerm" {
  key = "shared.tfstate"
}
```

### 4. Tagging Strategy
```hcl
tags = {
  Environment = var.environment
  ManagedBy   = "Terraform"
  Project     = var.project_name
  CostCenter  = var.cost_center
  Owner       = var.owner_email
}
```

### 5. Access Control
- Dev: Team access
- Staging: Limited team access
- Production: Restricted (CI/CD only)

## Common Patterns

### Pattern 1: Conditional Resources

```hcl
# Enable monitoring only in prod
resource "azurerm_monitor_action_group" "alerts" {
  count = var.environment == "prod" ? 1 : 0
  # ...
}
```

### Pattern 2: Environment-Specific Sizing

```hcl
locals {
  app_config = {
    dev = {
      cpu     = 0.25
      memory  = "0.5Gi"
      replicas = 1
    }
    staging = {
      cpu     = 0.5
      memory  = "1Gi"
      replicas = 2
    }
    prod = {
      cpu     = 1.0
      memory  = "2Gi"
      replicas = 3
    }
  }
  
  config = local.app_config[var.environment]
}

resource "azurerm_container_app" "app" {
  # ...
  template {
    container {
      cpu    = local.config.cpu
      memory = local.config.memory
    }
    min_replicas = local.config.replicas
  }
}
```

### Pattern 3: Data Source References

```hcl
# Reference existing resources
data "azurerm_container_app_environment" "existing" {
  count               = var.use_existing_env ? 1 : 0
  name                = var.existing_env_name
  resource_group_name = var.existing_rg_name
}
```

## Deployment Workflow

### Manual Deployment
```bash
# 1. Deploy to dev
cd dev && terraform apply -var-file=dev.tfvars

# 2. Test in dev
# Run tests, verify functionality

# 3. Deploy to staging
cd ../staging && terraform apply -var-file=staging.tfvars

# 4. UAT in staging
# User acceptance testing

# 5. Deploy to production
cd ../prod && terraform apply -var-file=prod.tfvars
```

### CI/CD Deployment (GitHub Actions)
See `.github/workflows/deploy-multi-env.yml`

## Troubleshooting

### Issue 1: Wrong Environment Deployed
```bash
# Verify current workspace/environment
terraform workspace show

# Check state file location
terraform state pull | jq -r '.terraform_version, .serial'
```

### Issue 2: Variable Override Not Working
```bash
# Check variable precedence
terraform console
> var.environment

# Explicitly specify var file
terraform apply -var-file=prod.tfvars -auto-approve=false
```

### Issue 3: Resource Name Conflicts
```
Error: A resource with the name already exists
```

**Solution**: Ensure unique naming with environment suffix
```hcl
name = "${var.project_name}-${var.environment}-app"
```

## Validation Questions

1. When would you use workspaces vs separate directories?
2. How do you prevent accidentally deploying dev config to prod?
3. What's the benefit of keeping environment configurations similar?
4. How do you handle environment-specific secrets?

## Security Considerations

### Secrets Management
```hcl
# ✅ Good: Use Azure Key Vault
data "azurerm_key_vault_secret" "db_password" {
  name         = "${var.environment}-db-password"
  key_vault_id = var.key_vault_id
}

# ❌ Bad: Store in variables
variable "db_password" {
  default = "MyP@ssw0rd"  # Never do this!
}
```

### State File Protection
- Enable Azure Storage encryption
- Use RBAC for access control
- Enable blob versioning
- Configure retention policies

## Cost Management

Track costs per environment:

```bash
# Tag-based cost analysis
az consumption usage list \
  --start-date 2026-02-01 \
  --end-date 2026-02-09 \
  --query "[?tags.Environment=='prod']"
```

## Cleanup

```bash
# Destroy in reverse order
cd prod && terraform destroy -var-file=prod.tfvars
cd ../staging && terraform destroy -var-file=staging.tfvars
cd ../dev && terraform destroy -var-file=dev.tfvars
```

## Next Steps

After completing Day 2:
- Proceed to **Day 3: Custom Modules and Reusability**
- You now understand multi-environment strategies
- Ready to create reusable modules

## Additional Resources

- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Managing Multiple Environments](https://developer.hashicorp.com/terraform/tutorials/modules/organize-configuration)
- [Azure Naming Conventions](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming)
