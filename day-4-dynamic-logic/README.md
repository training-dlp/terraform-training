# Day 4: Dynamic Logic and Validation

## Overview

Learn advanced Terraform techniques including dynamic blocks, conditional resources, and variable validation.

## Learning Objectives

- Use dynamic blocks effectively
- Implement conditional resource creation
- Write custom variable validations
- Use for_each and count
- Implement complex logic with locals

## Topics

### 1. Dynamic Blocks
```hcl
dynamic "env" {
  for_each = var.environment_variables
  content {
    name  = env.key
    value = env.value
  }
}
```

### 2. Conditional Resources
```hcl
resource "azurerm_monitor_action_group" "alerts" {
  count = var.enable_monitoring ? 1 : 0
  # ...
}
```

### 3. Variable Validation
```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

### 4. For Each
```hcl
resource "azurerm_storage_container" "containers" {
  for_each = toset(var.container_names)
  name     = each.value
  # ...
}
```

## Exercises

1. Create dynamic scaling rules
2. Implement conditional monitoring
3. Add custom validation rules
4. Use for_each for multiple resources

## Next Steps

Proceed to **Day 5: Sentinel Policies**
