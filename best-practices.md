# 🏗️ Terraform Best Practices (Azure)

A comprehensive guide to writing production-grade Terraform code on **Microsoft Azure** — with real-world examples for each practice.

---

## Table of Contents

1. [Use Remote State](#1-use-remote-state)
2. [Use Existing Shared and Community Modules](#2-use-existing-shared-and-community-modules)
3. [Import Existing Infrastructure](#3-import-existing-infrastructure)
4. [Avoid Hardcoding Variables](#4-avoid-hardcoding-variables)
5. [Always Format and Validate](#5-always-format-and-validate)
6. [Use a Consistent Naming Convention](#6-use-a-consistent-naming-convention)
7. [Tag Your Resources](#7-tag-your-resources)
8. [Introduce Policy as Code](#8-introduce-policy-as-code)
9. [Implement a Secrets Management Strategy](#9-implement-a-secrets-management-strategy)
10. [Test Your Terraform Code](#10-test-your-terraform-code)
11. [Enable Debug / Troubleshooting](#11-enable-debug--troubleshooting)
12. [Build Modules Wherever Possible](#12-build-modules-wherever-possible)
13. [Use Loops and Conditionals](#13-use-loops-and-conditionals)
14. [Use Functions](#14-use-functions)
15. [Take Advantage of Dynamic Blocks](#15-take-advantage-of-dynamic-blocks)
16. [Use Terraform Workspaces](#16-use-terraform-workspaces)
17. [Use the Lifecycle Block](#17-use-the-lifecycle-block)
18. [Use Variable Validations](#18-use-variable-validations)
19. [Leverage Helper Tools](#19-leverage-helper-tools)
20. [Take Advantage of IDE Extensions](#20-take-advantage-of-ide-extensions)

---

## 1. Use Remote State

Storing state locally is risky and makes collaboration impossible. Use **Azure Blob Storage** as a remote backend to share state across teams, enable state locking, and protect against data loss.

**Why it matters:**
- Enables team collaboration with a single source of truth
- Prevents concurrent state corruption via Azure Blob lease-based locking (built-in — no extra resource needed)
- Keeps sensitive state output off local disks

```hcl
# backend.tf — Azure Blob Storage remote backend
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "stmycomptfstate"
    container_name       = "tfstate"
    key                  = "prod/networking/terraform.tfstate"
  }
}
```

```hcl
# bootstrap/main.tf — one-time setup of the remote state infrastructure
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-terraform-state"
  location = "uksouth"
}

resource "azurerm_storage_account" "tfstate" {
  name                            = "stmycomptfstate"
  resource_group_name             = azurerm_resource_group.tfstate.name
  location                        = azurerm_resource_group.tfstate.location
  account_tier                    = "Standard"
  account_replication_type        = "GRS"       # Geo-redundant for durability
  allow_nested_items_to_be_public = false
  min_tls_version                 = "TLS1_2"

  blob_properties {
    versioning_enabled = true  # Recover from accidental state deletion
  }
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}
```

```bash
# Initialise with backend config passed at runtime (keeps secrets out of code)
terraform init \
  -backend-config="storage_account_name=stmycomptfstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=prod/networking/terraform.tfstate" \
  -backend-config="resource_group_name=rg-terraform-state"
```

> 💡 **Tip:** Use separate state files per environment (`dev/`, `staging/`, `prod/`) and per component (`networking/`, `compute/`, `database/`) to limit blast radius.

---

## 2. Use Existing Shared and Community Modules

Don't reinvent the wheel. The [Terraform Registry](https://registry.terraform.io/) has thousands of vetted, well-maintained modules for Azure.

**Why it matters:**
- Faster delivery — skip boilerplate
- Battle-tested by the community
- Regular security and feature updates

```hcl
# Use the community Azure Virtual Network module
module "vnet" {
  source  = "Azure/vnet/azurerm"
  version = "~> 4.0"

  resource_group_name = azurerm_resource_group.main.name
  vnet_location       = azurerm_resource_group.main.location
  vnet_name           = "vnet-myco-prod-uks"
  address_space       = ["10.0.0.0/16"]

  subnet_names    = ["snet-web", "snet-app", "snet-data"]
  subnet_prefixes = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

  tags = local.common_tags
}
```

```hcl
# Use the community AKS module
module "aks" {
  source  = "Azure/aks/azurerm"
  version = "~> 8.0"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  cluster_name        = "aks-myco-prod-uks"
  kubernetes_version  = "1.29"

  node_pools = {
    system = {
      vm_size    = "Standard_D2s_v3"
      node_count = 3
    }
  }

  tags = local.common_tags
}
```

> 💡 **Tip:** Always pin module versions using `version = "~> X.Y"` to avoid unexpected breaking changes during upgrades.

---

## 3. Import Existing Infrastructure

Already have Azure resources not managed by Terraform? Use `terraform import` (or the `import` block in Terraform 1.5+) to bring them under IaC management.

**Why it matters:**
- Avoids resource recreation or drift
- Gradually migrate existing infra to Terraform
- No downtime required

```hcl
# Terraform 1.5+ — declarative import block
import {
  to = azurerm_resource_group.existing
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-app"
}

resource "azurerm_resource_group" "existing" {
  name     = "rg-existing-app"
  location = "uksouth"
}
```

```hcl
# Import an existing Storage Account
import {
  to = azurerm_storage_account.existing_logs
  id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-logs/providers/Microsoft.Storage/storageAccounts/stmycomplogsprod"
}

resource "azurerm_storage_account" "existing_logs" {
  name                     = "stmycomplogsprod"
  resource_group_name      = "rg-logs"
  location                 = "uksouth"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}
```

```bash
# Classic CLI import (Terraform < 1.5)
terraform import azurerm_resource_group.existing \
  /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-existing-app

# Generate config from an existing resource (Terraform 1.5+)
terraform plan -generate-config-out=generated.tf

# Use aztfexport to bulk-export an entire resource group
aztfexport resource-group rg-existing-app
```

> 💡 **Tip:** After importing, always run `terraform plan` to confirm zero drift before committing the state.

---

## 4. Avoid Hardcoding Variables

Hardcoded values make code brittle, non-reusable, and difficult to promote across environments. Parameterise everything.

**Why it matters:**
- Reuse the same code across dev, staging, and prod
- Single source of truth per environment via `.tfvars`
- Reduces copy-paste errors

```hcl
# ❌ Bad — hardcoded values scattered in resources
resource "azurerm_linux_virtual_machine" "web" {
  name                = "vm-web-prod"
  resource_group_name = "rg-prod-app"
  location            = "uksouth"
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
}
```

```hcl
# ✅ Good — parameterised with typed variables
variable "vm_size" {
  description = "Azure VM SKU size"
  type        = string
  default     = "Standard_B2s"
}

variable "location" {
  description = "Azure region for all resources"
  type        = string
  default     = "uksouth"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureadmin"
}

resource "azurerm_linux_virtual_machine" "web" {
  name                = "${local.prefix}-vm-web"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  # ... other required blocks
}
```

```hcl
# prod.tfvars
location            = "uksouth"
resource_group_name = "rg-myco-prod-app"
vm_size             = "Standard_D4s_v3"
admin_username      = "azureadmin"
```

```bash
terraform apply -var-file="prod.tfvars"
```

---

## 5. Always Format and Validate

Enforce consistent formatting and catch errors before they reach `apply`. Make these part of your CI/CD pipeline.

**Why it matters:**
- Consistent, readable code across the team
- Catches syntax errors and misconfigurations early
- Reduces review friction

```bash
# Format all .tf files in place
terraform fmt -recursive

# Check formatting without changing files (great for CI)
terraform fmt -check -recursive

# Validate configuration syntax and internal consistency
terraform validate

# Full pre-apply workflow
terraform fmt -recursive && terraform validate && terraform plan
```

```yaml
# .github/workflows/terraform.yml — CI pipeline for Azure
name: Terraform CI

on:
  pull_request:
    branches: [main]

env:
  ARM_CLIENT_ID:       ${{ secrets.ARM_CLIENT_ID }}
  ARM_CLIENT_SECRET:   ${{ secrets.ARM_CLIENT_SECRET }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
  ARM_TENANT_ID:       ${{ secrets.ARM_TENANT_ID }}

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Format Check
        run: terraform fmt -check -recursive

      - name: Terraform Init
        run: terraform init -backend=false

      - name: Terraform Validate
        run: terraform validate
```

> 💡 **Tip:** Add a pre-commit hook using [`pre-commit`](https://pre-commit.com/) with `terraform_fmt` and `terraform_validate` hooks so formatting is enforced locally before any commit.

---

## 6. Use a Consistent Naming Convention

Resource names should be predictable and encode context. Azure has specific naming constraints (length limits, allowed characters per resource type) — plan your convention accordingly.

**Why it matters:**
- Makes resources easily discoverable in the Azure Portal
- Avoids naming collisions across environments
- Communicates ownership and purpose at a glance

```hcl
# Azure CAF recommended pattern: {resource-type}-{workload}-{env}-{region}-{instance}
# Reference: https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

locals {
  prefix = "${var.org}-${var.environment}-${var.short_location}"
  # e.g. myco-prod-uks
}

# Resource Group
resource "azurerm_resource_group" "app" {
  name     = "rg-${local.prefix}-app"          # rg-myco-prod-uks-app
  location = var.location
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.prefix}"  # vnet-myco-prod-uks
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  address_space       = ["10.0.0.0/16"]
}

# Storage Account — max 24 chars, lowercase alphanumeric only — no hyphens!
resource "azurerm_storage_account" "logs" {
  name                     = "st${var.org}${var.environment}logs"  # stmycoprodlogs
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Key Vault — max 24 chars
resource "azurerm_key_vault" "main" {
  name                = "kv-${local.prefix}"    # kv-myco-prod-uks
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
}

# Network Security Group
resource "azurerm_network_security_group" "web" {
  name                = "nsg-${local.prefix}-web"  # nsg-myco-prod-uks-web
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
}
```

```hcl
# variables.tf
variable "org" {
  description = "Organisation short name (lowercase, no hyphens)"
  type        = string
  default     = "myco"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "short_location" {
  description = "Short location code for naming (e.g. uks, euw, eus)"
  type        = string
  default     = "uks"
}
```

> 💡 **Tip:** Refer to the [Azure Naming Tool](https://github.com/mspnp/AzureNamingTool) for CAF-compliant naming generation and document your convention in a `CONVENTIONS.md` in your repo root.

---

## 7. Tag Your Resources

Tags are your best friend for cost allocation, security auditing, and operational visibility. Use `merge()` with a central `locals` block so every resource inherits the baseline.

**Why it matters:**
- Cost visibility by team, project, or environment in Azure Cost Management
- Enables automated governance via Azure Policy
- Simplifies incident response — who owns this resource?

```hcl
# locals.tf — centralised tag definition
locals {
  common_tags = {
    Organisation = "MyCompany"
    Environment  = var.environment
    Team         = var.team
    Project      = var.project
    ManagedBy    = "Terraform"
    Repository   = "github.com/myco/infra"
    CostCenter   = var.cost_center
  }
}

# Merge common tags with resource-specific tags
resource "azurerm_linux_virtual_machine" "web" {
  name                = "${local.prefix}-vm-web"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  size                = var.vm_size
  admin_username      = var.admin_username

  tags = merge(local.common_tags, {
    Role        = "web"
    Application = "frontend"
  })

  # ... other required blocks
}

resource "azurerm_storage_account" "data" {
  name                     = "st${var.org}${var.environment}data"
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = merge(local.common_tags, {
    DataClassification = "Confidential"
    Backup             = "required"
  })
}

resource "azurerm_resource_group" "app" {
  name     = "rg-${local.prefix}-app"
  location = var.location

  tags = local.common_tags  # RG tags don't auto-inherit to child resources in Azure
}
```

> 💡 **Tip:** Use [Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/overview) with `Deny` or `Append` effects to enforce required tags at the subscription level as a safety net alongside Terraform tagging.

---

## 8. Introduce Policy as Code

Use tools like [OPA / Conftest](https://www.conftest.dev/) or [Checkov](https://www.checkov.io/) to enforce guardrails — before `apply` ever runs.

**Why it matters:**
- Prevents non-compliant infrastructure from being created
- Decouples policy from application code
- Auditable, version-controlled rules

```bash
# Checkov — free, open source static analysis with Azure built-in rules
# Install: pip install checkov
checkov -d . --framework terraform
```

```yaml
# .checkov.yaml — skip specific checks with justification
skip-check:
  - CKV_AZURE_35  # Storage public access intentionally allowed for CDN origin
```

```rego
# policies/azure_storage.rego — OPA policy enforced via Conftest
package main

# Deny storage accounts without HTTPS-only enforcement
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  not resource.change.after.enable_https_traffic_only
  msg := sprintf(
    "Storage account '%s' must enforce HTTPS-only traffic",
    [resource.address]
  )
}

# Deny storage accounts with public blob access enabled
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_storage_account"
  resource.change.after.allow_nested_items_to_be_public == true
  msg := sprintf(
    "Storage account '%s' must not allow public blob access",
    [resource.address]
  )
}

# Deny Key Vaults without soft delete
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_key_vault"
  resource.change.after.soft_delete_retention_days < 7
  msg := sprintf(
    "Key Vault '%s' must have soft delete retention of at least 7 days",
    [resource.address]
  )
}

# Deny VMs without managed disks
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "azurerm_linux_virtual_machine"
  resource.change.after.os_disk[_].storage_account_type == ""
  msg := sprintf(
    "VM '%s' must use managed disks",
    [resource.address]
  )
}
```

```yaml
# .github/workflows/terraform.yml — policy gates in CI
- name: Generate Terraform Plan JSON
  run: terraform show -json tfplan > plan.json

- name: Run OPA Policy Checks
  run: conftest test plan.json --policy ./policies/

- name: Run Checkov Security Scan
  run: checkov -d . --framework terraform --output cli --output junitxml --output-file-path console,checkov-report.xml
```

---

## 9. Implement a Secrets Management Strategy

Never store secrets in `.tf` files, `.tfvars`, or state files. Use **Azure Key Vault** to retrieve secrets dynamically at runtime.

**Why it matters:**
- Secrets in state or code = a breach waiting to happen
- Dynamic retrieval means no secret rotation needed in code
- Aligns with zero-trust and Azure security best practices

```hcl
# provider.tf — authenticate via environment variables or Managed Identity
# Never put credentials directly in .tf files!
provider "azurerm" {
  features {}
  # Uses env vars: ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_SUBSCRIPTION_ID, ARM_TENANT_ID
  # Or automatically uses Managed Identity when running inside Azure (e.g. Azure DevOps, ACI)
}
```

```hcl
# secrets.tf — fetch secrets from Azure Key Vault at runtime
data "azurerm_client_config" "current" {}

data "azurerm_key_vault" "main" {
  name                = "kv-myco-prod-uks"
  resource_group_name = "rg-myco-prod-uks-shared"
}

data "azurerm_key_vault_secret" "db_password" {
  name         = "db-admin-password"
  key_vault_id = data.azurerm_key_vault.main.id
}

# Use the secret without ever hardcoding it
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${local.prefix}"
  resource_group_name          = azurerm_resource_group.app.name
  location                     = azurerm_resource_group.app.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value
  minimum_tls_version          = "1.2"
}
```

```hcl
# Best practice — use Managed Identity so apps don't need passwords at all
resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${local.prefix}-app"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
}

resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = data.azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_user_assigned_identity.app.principal_id

  secret_permissions = ["Get", "List"]
}

# Mark sensitive outputs to prevent them appearing in logs
output "db_connection_string" {
  value     = "Server=${azurerm_mssql_server.main.fully_qualified_domain_name};Database=mydb"
  sensitive = true
}
```

> ⚠️ **Warning:** Even with `sensitive = true`, values are stored in plain text in the state file. Azure Blob Storage encrypts state at rest by default — use Customer-Managed Keys (CMK) for higher compliance requirements.

---

## 10. Test Your Terraform Code

Treat infrastructure code like application code — write tests.

**Why it matters:**
- Catch regressions before they hit production
- Validate module behaviour with real Azure resources
- Build confidence for refactoring

```hcl
# Native Terraform test (terraform test) — Terraform 1.6+
# tests/storage_account.tftest.hcl

variables {
  environment         = "test"
  location            = "uksouth"
  resource_group_name = "rg-tftest-storage"
  org                 = "myco"
}

run "storage_account_is_secure" {
  command = plan

  assert {
    condition     = azurerm_storage_account.main.enable_https_traffic_only == true
    error_message = "Storage account must enforce HTTPS-only traffic"
  }

  assert {
    condition     = azurerm_storage_account.main.allow_nested_items_to_be_public == false
    error_message = "Storage account must not allow public blob access"
  }

  assert {
    condition     = azurerm_storage_account.main.min_tls_version == "TLS1_2"
    error_message = "Storage account must enforce TLS 1.2 minimum"
  }
}

run "storage_account_is_created" {
  command = apply

  assert {
    condition     = azurerm_storage_account.main.id != ""
    error_message = "Storage account was not created"
  }
}
```

```go
// Terratest example — tests/storage_account_test.go
package test

import (
    "os"
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestStorageAccountCreation(t *testing.T) {
    t.Parallel()

    terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
        TerraformDir: "../modules/azure-storage-account",
        Vars: map[string]interface{}{
            "environment":         "test",
            "location":            "uksouth",
            "resource_group_name": "rg-terratest-12345",
            "org":                 "myco",
        },
    })

    defer terraform.Destroy(t, terraformOptions)
    terraform.InitAndApply(t, terraformOptions)

    storageAccountName := terraform.Output(t, terraformOptions, "storage_account_name")
    assert.NotEmpty(t, storageAccountName)

    httpsOnly := terraform.Output(t, terraformOptions, "https_only")
    assert.Equal(t, "true", httpsOnly, "Storage account must enforce HTTPS-only traffic")
}
```

---

## 11. Enable Debug / Troubleshooting

When things go wrong, know how to extract detailed information quickly.

**Why it matters:**
- Faster incident resolution
- Understand Azure REST API interactions and error responses
- Debug cryptic plan/apply errors

```bash
# Set log level: TRACE, DEBUG, INFO, WARN, ERROR
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform-debug.log

# Log only the AzureRM provider (reduces noise)
export TF_LOG_PROVIDER=TRACE

# Enable Azure SDK HTTP request/response logging
export AZURE_HTTP_TRACING=true

# Run apply with full debug output saved to file
TF_LOG=TRACE terraform apply 2>&1 | tee apply-debug.log

# Inspect state
terraform show                                              # Human-readable current state
terraform state list                                        # List all resources in state
terraform state show azurerm_storage_account.logs          # Show a specific resource's state
terraform state show azurerm_virtual_network.main          # Inspect VNet state

# Refresh state to sync with actual Azure resources
terraform refresh

# Force unlock a stuck state (releases Azure Blob lease)
terraform force-unlock <LOCK_ID>

# Check provider versions in use
terraform version
terraform providers
```

```hcl
# Output useful debug info from your configuration
output "debug_vnet_id" {
  value       = azurerm_virtual_network.main.id
  description = "VNet resource ID — useful for debugging peering and NSG associations"
}

output "debug_subscription_id" {
  value       = data.azurerm_client_config.current.subscription_id
  description = "Confirms which Azure subscription Terraform is targeting"
}

output "debug_tenant_id" {
  value       = data.azurerm_client_config.current.tenant_id
  description = "Confirms the Azure AD tenant in use"
}
```

> 💡 **Tip:** Never commit files containing `TF_LOG=TRACE` output — they often contain ARM bearer tokens and sensitive resource metadata.

---

## 12. Build Modules Wherever Possible

Modules are Terraform's primary unit of reuse and abstraction. Structure your code so modules can be composed, tested, and versioned independently.

**Why it matters:**
- DRY infrastructure code
- Encapsulate complexity behind clean interfaces
- Version and share modules across teams

```
# Recommended Azure project structure
modules/
  azure-storage-account/
    main.tf
    variables.tf
    outputs.tf
    README.md
  azure-linux-vm/
    main.tf
    variables.tf
    outputs.tf
    README.md
  azure-key-vault/
    main.tf
    variables.tf
    outputs.tf
    README.md
  azure-vnet/
    main.tf
    variables.tf
    outputs.tf
    README.md

environments/
  prod/
    main.tf           ← calls modules
    variables.tf
    terraform.tfvars
    backend.tf
  dev/
    main.tf
    terraform.tfvars
    backend.tf
```

```hcl
# modules/azure-storage-account/main.tf
resource "azurerm_storage_account" "this" {
  name                            = var.name
  resource_group_name             = var.resource_group_name
  location                        = var.location
  account_tier                    = var.account_tier
  account_replication_type        = var.replication_type
  enable_https_traffic_only       = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags                            = var.tags
}

resource "azurerm_storage_account_network_rules" "this" {
  storage_account_id = azurerm_storage_account.this.id
  default_action     = "Deny"
  bypass             = ["AzureServices"]
  ip_rules           = var.allowed_ip_ranges
}
```

```hcl
# modules/azure-storage-account/variables.tf
variable "name" {
  description = "Storage account name (max 24 chars, lowercase alphanumeric only)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "account_tier" {
  description = "Storage account tier: Standard or Premium"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type: LRS, GRS, ZRS, GZRS"
  type        = string
  default     = "GRS"
}

variable "allowed_ip_ranges" {
  description = "List of IP ranges allowed to access the storage account"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
```

```hcl
# modules/azure-storage-account/outputs.tf
output "id" {
  description = "Resource ID of the storage account"
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.this.name
}

output "primary_blob_endpoint" {
  description = "Primary blob service endpoint"
  value       = azurerm_storage_account.this.primary_blob_endpoint
}
```

```hcl
# environments/prod/main.tf — consuming the module
module "app_logs_storage" {
  source = "../../modules/azure-storage-account"

  name                = "stmycoprodapplogsuks"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  replication_type    = "GRS"
  allowed_ip_ranges   = ["203.0.113.0/24"]
  tags                = local.common_tags
}
```

---

## 13. Use Loops and Conditionals

Replace repetitive resource blocks with `for_each`, `count`, and conditional expressions.

**Why it matters:**
- Eliminates copy-paste resource definitions
- Makes adding/removing instances a config change, not a code change
- Cleaner, more readable code

```hcl
# count — simple numeric repetition
variable "admin_object_ids" {
  type    = list(string)
  default = ["aaaaaaaa-0000-0000-0000-000000000001", "aaaaaaaa-0000-0000-0000-000000000002"]
}

resource "azurerm_role_assignment" "admins" {
  count                = length(var.admin_object_ids)
  scope                = azurerm_resource_group.app.id
  role_definition_name = "Contributor"
  principal_id         = var.admin_object_ids[count.index]
}
```

```hcl
# for_each with a set — preferred over count for named resources
variable "storage_containers" {
  type    = set(string)
  default = ["logs", "backups", "artifacts", "reports"]
}

resource "azurerm_storage_container" "containers" {
  for_each              = var.storage_containers
  name                  = each.key
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}
```

```hcl
# for_each with a map — richer configuration per item
variable "virtual_machines" {
  type = map(object({
    size       = string
    subnet_key = string
    os_disk_gb = number
  }))
  default = {
    web = { size = "Standard_B2s",    subnet_key = "snet-web",  os_disk_gb = 64  }
    app = { size = "Standard_D2s_v3", subnet_key = "snet-app",  os_disk_gb = 128 }
    db  = { size = "Standard_D4s_v3", subnet_key = "snet-data", os_disk_gb = 256 }
  }
}

resource "azurerm_linux_virtual_machine" "app" {
  for_each = var.virtual_machines

  name                = "${local.prefix}-vm-${each.key}"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  size                = each.value.size
  admin_username      = var.admin_username

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = each.value.os_disk_gb
  }

  tags = merge(local.common_tags, { Role = each.key })

  # ... network interface, image reference, etc.
}
```

```hcl
# Conditional — create diagnostic settings only in production
resource "azurerm_monitor_diagnostic_setting" "storage" {
  count = var.environment == "prod" ? 1 : 0

  name               = "diag-${local.prefix}-storage"
  target_resource_id = azurerm_storage_account.main.id
  storage_account_id = azurerm_storage_account.audit.id

  metric {
    category = "Transaction"
    enabled  = true
  }
}
```

---

## 14. Use Functions

Terraform has a rich set of built-in functions to transform and manipulate data without external scripting.

**Why it matters:**
- Keeps logic inside Terraform — no shell scripts needed
- Reduces boilerplate through data transformation
- Makes configurations self-documenting

```hcl
locals {
  # String functions
  env_upper   = upper(var.environment)                        # "PROD"
  sa_name     = lower("STMyCoAppLogs")                       # "stmycoapplogs"
  trimmed_org = trimspace("  myco  ")                        # "myco"

  # Enforce Azure storage account 24-char lowercase alphanumeric limit
  storage_name = substr(
    replace(lower("st-${var.org}-${var.environment}-logs"), "-", ""),
    0, 24
  ) # "stmycoprodlogs"

  # Collection functions
  all_locations    = ["uksouth", "ukwest", "westeurope"]
  primary_location = element(local.all_locations, 0)          # "uksouth"

  # Map merging
  base_tags  = { Env = "prod", ManagedBy = "Terraform" }
  extra_tags = { App = "myapp", Team = "platform" }
  all_tags   = merge(local.base_tags, local.extra_tags)

  # Encoding — base64 encode a cloud-init script for custom_data
  custom_data_b64 = base64encode(file("${path.module}/scripts/cloud-init.yaml"))

  # Lookup with default fallback
  vm_sku = lookup(var.vm_skus_by_env, var.environment, "Standard_B2s")

  # Flatten nested lists
  all_subnet_ids = flatten([
    module.vnet_primary.vnet_subnets,
    module.vnet_secondary.vnet_subnets,
  ])

  # Format a consistent Log Analytics workspace name
  law_name = format("law-%s-%s-%s", var.org, var.environment, var.short_location)

  # cidrsubnet — calculate subnet CIDRs dynamically
  private_subnets = [for i in range(3) : cidrsubnet("10.0.0.0/16", 8, i)]
  # ["10.0.0.0/24", "10.0.1.0/24", "10.0.2.0/24"]
}

# Use cidrsubnet to avoid hardcoding subnet CIDRs
variable "vnet_address_space" {
  default = "10.0.0.0/16"
}

resource "azurerm_subnet" "subnets" {
  count                = 3
  name                 = "snet-tier-${count.index}"
  resource_group_name  = azurerm_resource_group.app.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, count.index)]
  # Generates: 10.0.0.0/24, 10.0.1.0/24, 10.0.2.0/24
}
```

---

## 15. Take Advantage of Dynamic Blocks

`dynamic` blocks let you generate repeated nested blocks programmatically, keeping configs concise.

**Why it matters:**
- Replaces copy-pasted nested blocks (especially NSG rules)
- Makes rule sets and policies data-driven
- Cleaner diffs when adding/removing rules

```hcl
# Without dynamic — repetitive NSG rules, painful to maintain
resource "azurerm_network_security_group" "web_bad" {
  name                = "nsg-web"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location

  security_rule {
    name                       = "allow-http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "allow-https"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  # ...repeat for every rule
}
```

```hcl
# ✅ With dynamic — data-driven and scalable
variable "nsg_rules" {
  type = list(object({
    name                   = string
    priority               = number
    direction              = string
    access                 = string
    protocol               = string
    destination_port_range = string
    source_address_prefix  = string
    description            = string
  }))
  default = [
    {
      name                   = "allow-http"
      priority               = 100
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "80"
      source_address_prefix  = "*"
      description            = "Allow HTTP from internet"
    },
    {
      name                   = "allow-https"
      priority               = 110
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "443"
      source_address_prefix  = "*"
      description            = "Allow HTTPS from internet"
    },
    {
      name                   = "allow-app-internal"
      priority               = 200
      direction              = "Inbound"
      access                 = "Allow"
      protocol               = "Tcp"
      destination_port_range = "8080"
      source_address_prefix  = "10.0.2.0/24"
      description            = "Allow internal app tier traffic"
    },
  ]
}

resource "azurerm_network_security_group" "web" {
  name                = "nsg-${local.prefix}-web"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = "*"
      description                = security_rule.value.description
    }
  }

  tags = local.common_tags
}
```

---

## 16. Use Terraform Workspaces

Workspaces allow you to manage multiple environments from a single Terraform configuration with isolated state files stored in separate blobs on the same storage account.

**Why it matters:**
- Single codebase for dev/staging/prod
- State isolation between environments
- Environment-specific values without duplicating code

```hcl
# Use workspace name to drive environment-specific values
locals {
  env = terraform.workspace  # "dev", "staging", "prod"

  vm_sku = {
    dev     = "Standard_B2s"
    staging = "Standard_D2s_v3"
    prod    = "Standard_D4s_v3"
  }

  min_instances = {
    dev     = 1
    staging = 2
    prod    = 5
  }

  replication = {
    dev     = "LRS"
    staging = "ZRS"
    prod    = "GRS"
  }
}

resource "azurerm_storage_account" "app" {
  name                     = "st${var.org}${local.env}app"
  resource_group_name      = azurerm_resource_group.app.name
  location                 = azurerm_resource_group.app.location
  account_tier             = "Standard"
  account_replication_type = local.replication[local.env]
  tags                     = local.common_tags
}

resource "azurerm_linux_virtual_machine_scale_set" "web" {
  name                = "vmss-${local.prefix}-web"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  sku                 = local.vm_sku[local.env]
  instances           = local.min_instances[local.env]
  admin_username      = var.admin_username

  # ... other required blocks
}
```

```bash
# Workspace commands
terraform workspace new staging         # Create workspace
terraform workspace select prod         # Switch workspace
terraform workspace list                # List all workspaces
terraform workspace show                # Show current workspace

# Apply to a specific workspace
terraform workspace select prod && terraform apply -var-file="prod.tfvars"
```

> ⚠️ **Note:** Workspaces share the same Azure Blob Storage container — state is separated by blob key prefix. Use separate backends or separate Azure subscriptions for strict isolation in regulated environments.

---

## 17. Use the Lifecycle Block

Control how Terraform handles resource creation, updates, and deletion with `lifecycle` meta-arguments.

**Why it matters:**
- Prevent accidental deletion of critical Azure resources
- Allow zero-downtime replacements
- Ignore noisy attribute changes managed outside Terraform

```hcl
# create_before_destroy — zero-downtime replacement
resource "azurerm_linux_virtual_machine" "web" {
  name                = "${local.prefix}-vm-web"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  size                = var.vm_size
  admin_username      = var.admin_username

  lifecycle {
    create_before_destroy = true
  }

  # ... other required blocks
}
```

```hcl
# prevent_destroy — protect critical stateful resources from accidental deletion
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${local.prefix}"
  resource_group_name          = azurerm_resource_group.app.name
  location                     = azurerm_resource_group.app.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = data.azurerm_key_vault_secret.db_password.value

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_key_vault" "main" {
  name                = "kv-${local.prefix}"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  lifecycle {
    prevent_destroy = true
  }
}
```

```hcl
# ignore_changes — don't overwrite changes made outside Terraform
resource "azurerm_kubernetes_cluster" "main" {
  name                = "aks-${local.prefix}"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  dns_prefix          = "aks-${var.org}-${var.environment}"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2s_v3"
  }

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count,  # Managed by AKS Cluster Autoscaler
      kubernetes_version,               # Upgrades managed by Azure maintenance windows
      tags["LastUpdated"],              # Updated by deployment pipeline
    ]
  }

  # ... other required blocks
}
```

```hcl
# replace_triggered_by — force VM replacement when a dependent resource changes
resource "azurerm_linux_virtual_machine" "web_v2" {
  name                = "${local.prefix}-vm-web"
  resource_group_name = azurerm_resource_group.app.name
  location            = azurerm_resource_group.app.location
  size                = var.vm_size
  admin_username      = var.admin_username

  lifecycle {
    replace_triggered_by = [
      azurerm_network_interface.web  # Replace VM when NIC is recreated
    ]
  }

  # ... other required blocks
}
```

---

## 18. Use Variable Validations

Add `validation` blocks to variables to fail fast with clear error messages rather than obscure Azure API errors.

**Why it matters:**
- Catch invalid inputs before any Azure API calls are made
- Self-documenting constraints
- Better developer experience with actionable errors

```hcl
variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region"
  type        = string

  validation {
    condition = contains([
      "uksouth", "ukwest", "westeurope", "northeurope",
      "eastus", "eastus2", "westus2", "australiaeast"
    ], var.location)
    error_message = "location must be a supported Azure region slug (e.g. uksouth, westeurope)."
  }
}

variable "storage_account_name" {
  description = "Azure Storage Account name (max 24 chars, lowercase alphanumeric only)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 characters, lowercase letters and numbers only. No hyphens or underscores."
  }
}

variable "vm_size" {
  description = "Azure VM SKU size"
  type        = string

  validation {
    condition     = can(regex("^Standard_", var.vm_size))
    error_message = "vm_size must be a valid Azure VM SKU starting with 'Standard_' (e.g. Standard_D2s_v3)."
  }
}

variable "vnet_address_space" {
  description = "CIDR block for the Virtual Network"
  type        = string

  validation {
    condition     = can(cidrhost(var.vnet_address_space, 0))
    error_message = "vnet_address_space must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "replication_type" {
  description = "Storage account replication type"
  type        = string

  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.replication_type)
    error_message = "replication_type must be one of: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS."
  }
}

variable "tags" {
  description = "Resource tags — must include Team and CostCenter"
  type        = map(string)

  validation {
    condition     = contains(keys(var.tags), "Team") && contains(keys(var.tags), "CostCenter")
    error_message = "tags must include both 'Team' and 'CostCenter' keys."
  }
}
```

---

## 19. Leverage Helper Tools

A thriving ecosystem of tools makes Terraform development on Azure faster, safer, and more consistent.

| Tool | Purpose | Install |
|------|---------|---------|
| [tflint](https://github.com/terraform-linters/tflint) | Linting with Azure-specific rules | `brew install tflint` |
| [tfsec](https://github.com/aquasecurity/tfsec) | Security scanning (Azure rules built-in) | `brew install tfsec` |
| [checkov](https://www.checkov.io/) | Security & compliance scanning | `pip install checkov` |
| [infracost](https://www.infracost.io/) | Azure cost estimation before apply | `brew install infracost` |
| [aztfexport](https://github.com/Azure/aztfexport) | Export existing Azure resources to Terraform | `brew install aztfexport` |
| [tfswitch](https://tfswitch.warrensbox.com/) | Terraform version manager | `brew install warrensbox/tap/tfswitch` |
| [pre-commit](https://pre-commit.com/) | Git hooks for fmt/validate/lint | `brew install pre-commit` |
| [terragrunt](https://terragrunt.gruntwork.io/) | DRY wrapper for Terraform | `brew install terragrunt` |
| [atlantis](https://www.runatlantis.io/) | Pull request automation | Helm chart / Docker |

```bash
# tflint — with Azure ruleset plugin
cat > .tflint.hcl << 'EOF'
plugin "azurerm" {
  enabled = true
  version = "0.26.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
EOF
tflint --init && tflint --recursive

# tfsec — Azure-aware security scanning
tfsec . --include-passed
tfsec . --soft-fail    # Warn only, don't fail CI

# infracost — Azure cost breakdown before apply
infracost breakdown --path .
infracost diff --path . --compare-to baseline.json

# aztfexport — export an entire existing Azure resource group to Terraform
aztfexport resource-group rg-existing-app
```

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.92.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_tflint
        args:
          - --args=--config=.tflint.hcl
      - id: terraform_tfsec
      - id: infracost_breakdown
        args:
          - --args=--path=.
```

```bash
# Install and run pre-commit hooks
pre-commit install
pre-commit run --all-files
```

---

## 20. Take Advantage of IDE Extensions

The right editor setup dramatically improves productivity with autocompletion, inline docs, and real-time validation.

### VS Code

| Extension | Publisher | What it does |
|-----------|-----------|-------------|
| **HashiCorp Terraform** | HashiCorp | Syntax highlighting, autocompletion, hover docs, go-to-definition |
| **Azure Terraform** | Microsoft | Azure-specific Terraform workflows, Cloud Shell integration |
| **Azure Tools** | Microsoft | Browse and manage Azure resources from the editor |
| **GitLens** | GitKraken | Inline blame & history for `.tf` files |
| **Error Lens** | Alexander | Inline error highlighting |

```json
// .vscode/settings.json — recommended project settings for Azure Terraform
{
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true,
    "editor.tabSize": 2
  },
  "[terraform-vars]": {
    "editor.defaultFormatter": "hashicorp.terraform",
    "editor.formatOnSave": true
  },
  "terraform.languageServer.enable": true,
  "terraform.languageServer.args": ["serve"],
  "terraform.codelens.referenceCount": true,
  "azureTerraform.terminal": "integrated",
  "azureTerraform.cloudShellDirectory": "clouddrive/terraform"
}
```

### JetBrains IDEs (IntelliJ, GoLand, Rider)

- **HashiCorp Terraform** plugin — available in the JetBrains Marketplace
- **Azure Toolkit for IntelliJ** — browse and manage Azure resources inline
- Provides full language support, variable resolution, and resource navigation

### Vim / Neovim

```vim
" Install via vim-plug or lazy.nvim
Plug 'hashivim/vim-terraform'           " Syntax + fmt on save
Plug 'nvim-treesitter/nvim-treesitter'  " Better syntax parsing

" .vimrc
let g:terraform_fmt_on_save = 1
let g:terraform_align = 1
```

### Useful Azure-Specific Snippets for VS Code

```json
// .vscode/terraform.code-snippets
{
  "Azure Resource Group": {
    "prefix": "azrg",
    "body": [
      "resource \"azurerm_resource_group\" \"${1:name}\" {",
      "  name     = \"rg-${2:workload}-${3:env}-${4:location}\"",
      "  location = var.location",
      "  tags     = local.common_tags",
      "}",
      ""
    ],
    "description": "Azure Resource Group"
  },
  "Azure Storage Account": {
    "prefix": "azsa",
    "body": [
      "resource \"azurerm_storage_account\" \"${1:name}\" {",
      "  name                            = \"${2:storageaccountname}\"",
      "  resource_group_name             = azurerm_resource_group.${3:rg}.name",
      "  location                        = azurerm_resource_group.${3:rg}.location",
      "  account_tier                    = \"Standard\"",
      "  account_replication_type        = \"GRS\"",
      "  enable_https_traffic_only       = true",
      "  min_tls_version                 = \"TLS1_2\"",
      "  allow_nested_items_to_be_public = false",
      "  tags                            = local.common_tags",
      "}",
      ""
    ],
    "description": "Secure Azure Storage Account"
  },
  "AzureRM Provider Block": {
    "prefix": "azprovider",
    "body": [
      "terraform {",
      "  required_version = \">= 1.6\"",
      "",
      "  required_providers {",
      "    azurerm = {",
      "      source  = \"hashicorp/azurerm\"",
      "      version = \"~> 3.0\"",
      "    }",
      "  }",
      "}",
      "",
      "provider \"azurerm\" {",
      "  features {}",
      "}",
      ""
    ],
    "description": "Terraform AzureRM provider block"
  },
  "Azure Backend Config": {
    "prefix": "azbackend",
    "body": [
      "backend \"azurerm\" {",
      "  resource_group_name  = \"${1:rg-terraform-state}\"",
      "  storage_account_name = \"${2:stmycomptfstate}\"",
      "  container_name       = \"tfstate\"",
      "  key                  = \"${3:prod/component/terraform.tfstate}\"",
      "}",
      ""
    ],
    "description": "Azure Blob Storage backend config"
  }
}
```

---

## Quick Reference Cheatsheet

```bash
# Initialise                      terraform init
# Format                          terraform fmt -recursive
# Validate                        terraform validate
# Plan                            terraform plan -out=tfplan
# Apply                           terraform apply tfplan
# Destroy                         terraform destroy
# Show state                      terraform show
# List resources                  terraform state list
# Import resource                 terraform import <address> <azure-resource-id>
# Refresh state                   terraform refresh
# Workspace                       terraform workspace select <name>
# Debug                           TF_LOG=DEBUG terraform apply
# Azure auth check                az account show
# Export existing Azure infra     aztfexport resource-group <rg-name>
```

### Azure Resource ID Format (for `terraform import`)

```
/subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/{provider}/{resourceType}/{resourceName}

# Examples:
/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-myco-prod-uks-app
/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-myco-prod-uks-app/providers/Microsoft.Storage/storageAccounts/stmycoprodlogs
/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-myco-prod-uks-app/providers/Microsoft.Network/virtualNetworks/vnet-myco-prod-uks
/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-myco-prod-uks-app/providers/Microsoft.KeyVault/vaults/kv-myco-prod-uks
```

---

## Contributing

Found an issue or want to add a new best practice? Open a PR! Please include:
- A clear explanation of the practice
- A working Terraform + Azure example
- Notes on when to apply (and when not to)

---
Courtesy URLs
https://www.terraform-best-practices.com/
https://developer.hashicorp.com/terraform/cloud-docs/recommended-practices
---
