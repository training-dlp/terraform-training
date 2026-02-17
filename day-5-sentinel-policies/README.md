# Day 5: Terraform Enterprise Policy as Code (Sentinel)

## Overview

Learn how to implement Policy as Code using Sentinel to enforce organizational standards, security requirements, and compliance rules.

## Learning Objectives

- Understand Policy as Code concepts
- Write Sentinel policies
- Test policies against Terraform plans
- Implement soft-fail vs hard-fail policies
- Create policy sets

## What is Sentinel?

Sentinel is HashiCorp's Policy as Code framework that allows you to enforce policies on Terraform runs before infrastructure is provisioned.

## Policy Enforcement Levels

- **Advisory**: Warning only, never fails
- **Soft Mandatory**: Must pass unless overridden
- **Hard Mandatory**: Must always pass

## Topics Covered

### 1. Sentinel Language Basics
```sentinel
import "tfplan/v2" as tfplan

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.change.actions not contains "delete"
  }
}
```

### 2. Common Policy Examples

**Require Tags:**
```sentinel
mandatory_tags = ["Environment", "Owner", "CostCenter"]

main = rule {
  all resources as _, resource {
    all mandatory_tags as tag {
      resource.values.tags contains tag
    }
  }
}
```

**Enforce Naming Convention:**
```sentinel
naming_pattern = "^(rg|st|ca)-[a-z0-9-]+-(dev|staging|prod)-"

main = rule {
  all resource_groups as _, rg {
    rg.values.name matches naming_pattern
  }
}
```

**Restrict Instance Sizes:**
```sentinel
allowed_sizes = ["Standard", "Premium"]

main = rule {
  all storage_accounts as _, sa {
    sa.values.account_tier in allowed_sizes
  }
}
```

## Exercises

### Exercise 1: Tag Enforcement Policy (20 minutes)

Create a policy requiring specific tags on all resources.

### Exercise 2: Naming Convention Policy (20 minutes)

Enforce naming standards for Azure resources.

### Exercise 3: Cost Control Policy (20 minutes)

Prevent creation of expensive resource SKUs.

### Exercise 4: Security Policy (20 minutes)

Ensure encryption and network security settings.

## Policy Structure

```
day-5-sentinel-policies/
├── policies/
│   ├── require-tags.sentinel
│   ├── naming-convention.sentinel
│   ├── cost-control.sentinel
│   └── security-baseline.sentinel
├── test-cases/
│   ├── require-tags/
│   │   ├── pass.json
│   │   └── fail.json
│   └── ...
└── sentinel.hcl
```

## Testing Policies

```bash
# Test a single policy
sentinel test -run=require-tags policies/require-tags.sentinel

# Test all policies
sentinel test

# Apply policies (in TFE/TFC)
sentinel apply -config sentinel.hcl
```

## Best Practices

1. **Start with Advisory**: Test policies before enforcing
2. **Clear Error Messages**: Help users understand violations
3. **Test Thoroughly**: Include pass and fail cases
4. **Document Policies**: Explain the "why" behind each rule
5. **Version Control**: Track policy changes over time
6. **Policy Sets**: Group related policies
7. **Exemption Process**: Define override procedures

## Example Policies

### Require Specific Tags
```sentinel
import "tfplan/v2" as tfplan

mandatory_tags = ["Environment", "Owner", "Project", "ManagedBy"]

get_resources = func(type) {
  resources = []
  for tfplan.resource_changes as rc {
    if rc.type == type and rc.mode == "managed" and
      (rc.change.actions contains "create" or rc.change.actions contains "update") {
      append(resources, rc)
    }
  }
  return resources
}

resource_has_required_tags = func(resource) {
  tags = resource.change.after.tags else {}
  for mandatory_tags as tag {
    if tag not in keys(tags) {
      print("Missing required tag:", tag, "on", resource.address)
      return false
    }
  }
  return true
}

main = rule {
  all get_resources("azurerm_resource_group") as rg {
    resource_has_required_tags(rg)
  }
}
```

### Naming Convention
```sentinel
import "tfplan/v2" as tfplan
import "strings"

# Valid prefixes for different resource types
resource_prefixes = {
  "azurerm_resource_group":      "rg-",
  "azurerm_storage_account":     "st",
  "azurerm_container_app":       "ca-",
  "azurerm_log_analytics_workspace": "log-",
}

# Valid environments
valid_environments = ["dev", "staging", "prod"]

validate_naming = func(resource) {
  type = resource.type
  name = resource.change.after.name
  
  # Check prefix
  if type in keys(resource_prefixes) {
    prefix = resource_prefixes[type]
    if not strings.has_prefix(name, prefix) {
      print("Resource", name, "must start with", prefix)
      return false
    }
    
    # Check environment suffix
    has_valid_env = false
    for valid_environments as env {
      if strings.has_suffix(name, "-" + env) or strings.contains(name, "-" + env + "-") {
        has_valid_env = true
      }
    }
    if not has_valid_env {
      print("Resource", name, "must include environment (dev/staging/prod)")
      return false
    }
  }
  
  return true
}

main = rule {
  all tfplan.resource_changes as _, rc {
    rc.mode == "data" or validate_naming(rc)
  }
}
```

## Validation Questions

1. What's the difference between advisory and hard mandatory policies?
2. How do you test Sentinel policies before enforcement?
3. What are some common use cases for Sentinel in Azure?
4. How do you handle policy exceptions?

## Common Use Cases

### 1. Security Compliance
- Enforce encryption
- Require private endpoints
- Mandate network security rules

### 2. Cost Management
- Limit resource SKUs
- Enforce auto-shutdown policies
- Restrict expensive regions

### 3. Operational Standards
- Require tags for all resources
- Enforce naming conventions
- Mandate backup policies

### 4. Governance
- Restrict resource types
- Enforce RBAC settings
- Require monitoring configuration

## Sentinel vs OPA

| Feature | Sentinel | OPA (Open Policy Agent) |
|---------|----------|-------------------------|
| Language | Sentinel | Rego |
| Integration | Native to Terraform Cloud/Enterprise | Requires additional tooling |
| Ease of Use | Simpler syntax | More flexible but complex |
| Testing | Built-in test framework | Separate testing tools |

## Workshop Wrap-Up

Congratulations! You've completed the Terraform Advanced Workshop:

✅ Day 1: State Management
✅ Day 2: Multi-Environment Deployment
✅ Day 3: Custom Modules
✅ Day 4: Dynamic Logic
✅ Day 5: Policy as Code

### Key Takeaways

1. Always use remote state for team collaboration
2. Separate environments with clear naming conventions
3. Create reusable modules for common patterns
4. Validate inputs and use dynamic logic wisely
5. Enforce standards with policy as code

### Next Steps

- Implement these patterns in your projects
- Set up CI/CD with GitHub Actions
- Explore Terraform Cloud/Enterprise features
- Join the Terraform community

## Additional Resources

- [Sentinel Documentation](https://docs.hashicorp.com/sentinel)
- [Sentinel Language Spec](https://docs.hashicorp.com/sentinel/language)
- [Policy Examples](https://github.com/hashicorp/terraform-sentinel-policies)
- [Terraform Cloud Policies](https://www.terraform.io/cloud-docs/policy-enforcement)
