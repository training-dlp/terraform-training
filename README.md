# Terraform Advanced Workshop - 5 Days

This repository contains all materials for a 5-day advanced Terraform workshop focusing on Azure Container Apps with GitHub Actions CI/CD.

## Workshop Overview

- **Day 1**: State Management (Local and Remote)
- **Day 2**: Multi-Environment Deployment
- **Day 3**: Custom Modules and Reusability
- **Day 4**: Dynamic Logic and Validation
- **Day 5**: Terraform Enterprise Policy as Code (Sentinel)

## Prerequisites

### Required Tools
- Azure CLI (latest version)
- Terraform (>= 1.6.0)
- Git
- GitHub Account
- Azure Subscription
- Python 3.9+ (for the sample application)
- Code editor (VS Code recommended)

### Azure Resources Access
- Contributor access to Azure subscription
- Ability to create Service Principals

## Initial Setup

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd terraform-training
```

### 2. Azure Authentication Setup

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "<your-subscription-id>"

# Create a Service Principal for Terraform
az ad sp create-for-rbac --name "terraform-training-sp" \
  --role="Contributor" \
  --scopes="/subscriptions/<your-subscription-id>"
```

**Save the output** - you'll need:
- `appId` (Client ID)
- `password` (Client Secret)
- `tenant` (Tenant ID)

### 3. GitHub Secrets Configuration

Add the following secrets to your GitHub repository (Settings → Secrets and variables → Actions):

```
ARM_CLIENT_ID=<appId from step 2>
ARM_CLIENT_SECRET=<password from step 2>
ARM_SUBSCRIPTION_ID=<your-subscription-id>
ARM_TENANT_ID=<tenant from step 2>
```

### 4. Azure Storage for Remote State

```bash
# Create resource group for state storage
az group create --name rg-terraform-state --location eastus

# Create storage account
az storage account create \
  --name tfstateworkshop$(date +%s | tail -c 5) \
  --resource-group rg-terraform-state \
  --location eastus \
  --sku Standard_LRS \
  --encryption-services blob

# Create container
az storage container create \
  --name tfstate \
  --account-name <storage-account-name>
```

**Note**: Save your storage account name for later use.

### 5. Initial Application Setup

```bash
cd initial-setup
terraform init
terraform plan
terraform apply
```

## Workshop Structure

### Day 1: State Management
- **Location**: `day-1-state-management/`
- Learn local vs remote state
- Implement Azure Storage backend
- State locking and consistency
- **Exercises**: Migrate from local to remote state

### Day 2: Multi-Environment Deployment
- **Location**: `day-2-multi-env/`
- Environment separation strategies
- Workspace management
- Variable files per environment
- **Exercises**: Deploy to dev, staging, and prod

### Day 3: Custom Modules
- **Location**: `day-3-custom-modules/`
- Module creation best practices
- Input variables and outputs
- Module versioning
- **Exercises**: Create reusable container-app module

### Day 4: Dynamic Logic and Validation
- **Location**: `day-4-dynamic-logic/`
- Dynamic blocks
- Conditional resources
- Variable validation
- **Exercises**: Dynamic scaling rules

### Day 5: Sentinel Policies
- **Location**: `day-5-sentinel-policies/`
- Policy as Code concepts
- Writing Sentinel policies
- Testing policies
- **Exercises**: Enforce tagging and naming conventions

## Quick Start

Each day's folder contains:
- `README.md` - Detailed instructions
- Terraform configuration files
- Example outputs
- Exercise solutions

## Cleanup

```bash
# Destroy resources for each day
cd day-X-<topic>
terraform destroy

# Finally, destroy the state storage (optional)
az group delete --name rg-terraform-state
```

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   - Verify Service Principal credentials
   - Check Azure subscription access

2. **State Lock Issues**
   - Ensure no concurrent Terraform operations
   - Check storage account access

3. **Module Not Found**
   - Run `terraform init` to download modules
   - Check module source paths

## Additional Resources

- [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Sentinel Documentation](https://docs.hashicorp.com/sentinel)

## Support

For issues or questions during the workshop:
1. Check the day's README.md
2. Review the troubleshooting section
3. Raise an issue in this repository

---

**Workshop Instructor**: [Your Name]
**Last Updated**: February 2026
