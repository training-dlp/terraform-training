# Day 1: State Management (Local and Remote)

## Overview

Learn how Terraform manages state, the differences between local and remote state, and best practices for state management in team environments.

## Learning Objectives

- Understand Terraform state file structure
- Implement local state management
- Configure remote state with Azure Storage
- Implement state locking
- Migrate from local to remote state
- Use state commands for inspection and manipulation

## Prerequisites

- Completed initial setup
- Azure Storage account created for remote state
- Service Principal configured

## Topics Covered

### 1. Local State
- Default state behavior
- State file location
- Pros and cons
- When to use local state

### 2. Remote State
- Azure Storage backend configuration
- State locking with lease mechanism
- Encryption at rest
- Access control

### 3. State Commands
- `terraform state list`
- `terraform state show`
- `terraform state mv`
- `terraform state rm`
- `terraform state pull/push`

## Exercises

### Exercise 1: Local State (15 minutes)

Deploy infrastructure with local state:

```bash
cd day-1-state-management/local-state
terraform init
terraform plan
terraform apply
```

Inspect the state:

```bash
# List all resources
terraform state list

# Show specific resource
terraform state show azurerm_resource_group.example

# View state file
cat terraform.tfstate
```

### Exercise 2: Remote State Migration (20 minutes)

Migrate to remote state:

```bash
cd ../remote-state

# Update backend.tf with your storage account details
# Then initialize with migration
terraform init -migrate-state

# Verify state is now remote
terraform state list
```

### Exercise 3: State Locking (10 minutes)

Test concurrent operations:

```bash
# Terminal 1
terraform plan

# Terminal 2 (while plan is running)
terraform plan
# Should see lock acquisition message
```

### Exercise 4: State Manipulation (15 minutes)

Practice state commands:

```bash
# List resources
terraform state list

# Move resource
terraform state mv azurerm_resource_group.example azurerm_resource_group.main

# Remove resource from state (not from Azure)
terraform state rm azurerm_resource_group.test
```

## Architecture Comparison

### Local State
```
Developer Machine
├── .terraform/
├── terraform.tfstate       ← State stored locally
├── terraform.tfstate.backup
└── *.tf files
```

### Remote State
```
Developer Machine           Azure Storage
├── .terraform/            ┌─────────────────┐
├── *.tf files             │  Blob Container │
└── backend.tf ───────────>│  - tfstate      │
                           │  - Lock (Lease) │
                           └─────────────────┘
```

## Best Practices

1. **Never commit state files to Git**
   - Add `*.tfstate*` to `.gitignore`
   
2. **Always use remote state for teams**
   - Ensures single source of truth
   - Enables collaboration

3. **Enable state locking**
   - Prevents concurrent modifications
   - Reduces risk of corruption

4. **Encrypt state at rest**
   - Azure Storage encryption enabled by default
   - Consider customer-managed keys for sensitive data

5. **Regular state backups**
   - Azure Storage versioning
   - Automated backup policies

6. **Limit state access**
   - Use Azure RBAC
   - Principle of least privilege

## Common Issues and Solutions

### Issue 1: State Lock Timeout
```
Error: Error locking state: Error acquiring the state lock
```

**Solution:**
```bash
# Force unlock (use with caution)
terraform force-unlock <LOCK_ID>
```

### Issue 2: State Drift
```
Error: Resource not found in Azure but exists in state
```

**Solution:**
```bash
# Refresh state
terraform refresh

# Or reimport
terraform import azurerm_resource_group.main /subscriptions/.../resourceGroups/...
```

### Issue 3: Backend Configuration Error
```
Error: Failed to get existing workspaces: storage account not found
```

**Solution:**
- Verify storage account name in backend configuration
- Check Azure credentials
- Ensure storage account exists

## Key Files

- `local-state/main.tf` - Infrastructure with local state
- `remote-state/main.tf` - Same infrastructure configured for remote state
- `remote-state/backend.tf` - Azure Storage backend configuration
- `remote-state/terraform.tfvars` - Backend configuration values

## State File Security

**IMPORTANT**: Never commit these files:
- `terraform.tfstate`
- `terraform.tfstate.backup`
- `*.tfvars` (if containing secrets)

Add to `.gitignore`:
```
*.tfstate
*.tfstate.*
.terraform/
*.tfvars
override.tf
override.tf.json
```

## Validation Questions

1. What happens if two people run `terraform apply` simultaneously with local state?
2. How does Azure Storage provide state locking?
3. When would you use `terraform state rm`?
4. What's the difference between `terraform refresh` and `terraform apply -refresh-only`?

## Next Steps

After completing Day 1:
- Proceed to **Day 2: Multi-Environment Deployment**
- All future exercises will use remote state
- Keep your backend configuration for reference

## Additional Resources

- [Terraform State Documentation](https://developer.hashicorp.com/terraform/language/state)
- [Azure Storage Backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
- [State Locking](https://developer.hashicorp.com/terraform/language/state/locking)
