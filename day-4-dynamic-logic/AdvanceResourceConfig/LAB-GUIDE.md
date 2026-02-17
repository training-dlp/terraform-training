# Azure Container Apps with Terraform - Lab Guide
## Complete Hands-On Training Materials

**Duration:** One Full Day (8 hours)  
**Level:** Advanced  
**Prerequisites:** Basic Terraform, Azure CLI, Container concepts

---

## Table of Contents

1. [Environment Setup](#environment-setup)
2. [Lab 1.1: Remote State Configuration](#lab-11-remote-state-configuration)
3. [Lab 1.2: Multi-Environment with Workspaces](#lab-12-multi-environment-with-workspaces)
4. [Lab 2.1: Dynamic Configuration](#lab-21-dynamic-configuration)
5. [Lab 2.2: Multi-Container Apps with for_each](#lab-22-multi-container-apps-with-for_each)
6. [Lab 3.1: Creating a Reusable Module](#lab-31-creating-a-reusable-module)
7. [Lab 3.2: Module Composition](#lab-32-module-composition)
8. [Lab 4.1: Secure Container App with Key Vault](#lab-41-secure-container-app-with-key-vault)
9. [Lab 4.2: Network-Isolated Container App](#lab-42-network-isolated-container-app)
10. [Troubleshooting Guide](#troubleshooting-guide)

---

## Environment Setup

### Required Tools

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Terraform
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installations
az --version
terraform --version
```

### Azure Login

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "YOUR_SUBSCRIPTION_ID"

# Verify
az account show
```

### Prepare Workspace

```bash
# Create lab directory
mkdir -p ~/terraform-labs
cd ~/terraform-labs

# Copy lab files
cp /path/to/lab-files/* .

# Initialize Git (optional)
git init
```

---

## Lab 1.1: Remote State Configuration

**Objective:** Set up Azure Blob Storage as a remote backend for Terraform state with locking.

### Steps

1. **Create Storage Account for State**

```bash
cd ~/terraform-labs/lab1.1

# Review the configuration
cat lab1.1-remote-state-setup.tf

# Initialize and apply
terraform init
terraform plan
terraform apply
```

2. **Capture Outputs**

```bash
# Save storage account name
terraform output storage_account_name
terraform output backend_configuration
```

3. **Create Backend Configuration**

```bash
# Create backend.tf with the output configuration
terraform output -raw backend_configuration > backend.tf
```

4. **Migrate State**

```bash
# Reinitialize with backend
terraform init -reconfigure

# Confirm migration
# Answer 'yes' when prompted
```

5. **Verify Remote State**

```bash
# Check state in Azure
az storage blob list \
  --account-name $(terraform output -raw storage_account_name) \
  --container-name tfstate \
  --output table
```

### Expected Results
- ✅ Storage account created
- ✅ Container created for state
- ✅ State file migrated to Azure
- ✅ State locking enabled

### Cleanup
```bash
# Keep for next labs - DO NOT destroy yet
```

---

## Lab 1.2: Multi-Environment with Workspaces

**Objective:** Deploy Container Apps to multiple environments using Terraform workspaces.

### Steps

1. **Update Backend Configuration**

Edit `lab1.2-workspaces.tf` and update the storage account name from Lab 1.1.

2. **Create Development Workspace**

```bash
cd ~/terraform-labs/lab1.2

# Create and switch to dev workspace
terraform workspace new dev

# Deploy to dev
terraform init
terraform plan
terraform apply
```

3. **Create Staging Workspace**

```bash
# Create staging workspace
terraform workspace new staging

# Deploy to staging
terraform plan
terraform apply
```

4. **Create Production Workspace**

```bash
# Create prod workspace
terraform workspace new prod

# Deploy to production
terraform plan
terraform apply
```

5. **Compare Environments**

```bash
# List workspaces
terraform workspace list

# View dev resources
terraform workspace select dev
terraform state list

# View prod resources
terraform workspace select prod
terraform state list

# Compare configurations
terraform workspace select dev
terraform output environment_config

terraform workspace select prod
terraform output environment_config
```

6. **Test Applications**

```bash
# Get URLs for each environment
terraform workspace select dev
terraform output webapp_url
terraform output api_url

terraform workspace select staging
terraform output webapp_url
terraform output api_url

terraform workspace select prod
terraform output webapp_url
terraform output api_url

# Test with curl
curl $(terraform output -raw webapp_url)
```

### Expected Results
- ✅ 3 separate environments deployed
- ✅ Different configurations per environment
- ✅ Isolated state files
- ✅ Environment-specific resources

### Cleanup
```bash
# Cleanup each workspace
terraform workspace select dev
terraform destroy

terraform workspace select staging
terraform destroy

terraform workspace select prod
terraform destroy
```

---

## Lab 2.1: Dynamic Configuration

**Objective:** Create Container Apps with dynamic blocks for flexible configuration.

### Steps

1. **Review Configuration**

```bash
cd ~/terraform-labs/lab2.1

# Examine the dynamic blocks
grep -A 10 "dynamic" lab2.1-dynamic-configuration.tf
```

2. **Customize Variables (Optional)**

```bash
# Create terraform.tfvars
cat > terraform.tfvars <<EOF
environment_variables = {
  "CUSTOM_VAR" = {
    name  = "CUSTOM_VAR"
    value = "custom_value"
  }
}
EOF
```

3. **Deploy**

```bash
terraform init
terraform plan
terraform apply
```

4. **Verify Dynamic Configuration**

```bash
# Check deployed apps
az containerapp list \
  --resource-group rg-containerapp-dynamic \
  --output table

# View environment variables
az containerapp show \
  --name ca-dynamic-config \
  --resource-group rg-containerapp-dynamic \
  --query "properties.template.containers[0].env"

# View secrets (names only)
az containerapp show \
  --name ca-dynamic-config \
  --resource-group rg-containerapp-dynamic \
  --query "properties.configuration.secrets[].name"
```

5. **Test Applications**

```bash
# Get URLs
terraform output dynamic_app_url
terraform output dynamic_scaling_app_url
terraform output advanced_app_url

# Test each app
curl $(terraform output -raw dynamic_app_url)
curl $(terraform output -raw dynamic_scaling_app_url)
curl $(terraform output -raw advanced_app_url)
```

### Expected Results
- ✅ 3 container apps with dynamic configuration
- ✅ Environment variables configured dynamically
- ✅ Secrets configured dynamically
- ✅ Volume mounts configured dynamically
- ✅ Scale rules configured dynamically

### Cleanup
```bash
terraform destroy
```

---

## Lab 2.2: Multi-Container Apps with for_each

**Objective:** Deploy multiple Container Apps using for_each iteration.

### Steps

1. **Review Application Map**

```bash
cd ~/terraform-labs/lab2.2

# View the applications to be deployed
grep -A 20 "variable \"container_apps\"" lab2.2-foreach-iteration.tf
```

2. **Deploy All Applications**

```bash
terraform init
terraform plan
terraform apply
```

3. **Explore Deployed Apps**

```bash
# List all container apps
az containerapp list \
  --resource-group rg-containerapp-foreach \
  --output table

# View specific app
az containerapp show \
  --name ca-frontend \
  --resource-group rg-containerapp-foreach
```

4. **Test Applications**

```bash
# Get all URLs
terraform output app_urls
terraform output dapr_app_urls

# Test frontend
curl $(terraform output -json app_urls | jq -r '.frontend')

# Test backend
curl $(terraform output -json app_urls | jq -r '.backend')

# Test Dapr apps
curl $(terraform output -json dapr_app_urls | jq -r '.["orders-service"]')
```

5. **Scale Individual Apps**

```bash
# Scale backend app
az containerapp update \
  --name ca-backend \
  --resource-group rg-containerapp-foreach \
  --max-replicas 20
```

6. **Modify Configuration**

```bash
# Add a new app to the map
# Edit lab2.2-foreach-iteration.tf and add to container_apps variable

# Apply changes
terraform plan
terraform apply
```

### Expected Results
- ✅ 7+ container apps deployed
- ✅ Standard and Dapr-enabled apps
- ✅ Shared infrastructure
- ✅ Easy to add/remove apps
- ✅ Consistent configuration

### Cleanup
```bash
terraform destroy
```

---

## Lab 3.1: Creating a Reusable Module

**Objective:** Build and use a reusable Terraform module for Container Apps.

### Steps

1. **Review Module Structure**

```bash
cd ~/terraform-labs

# Module structure
tree modules/container-app/

# Output:
# modules/container-app/
# ├── main.tf
# ├── variables.tf
# ├── outputs.tf
# └── README.md
```

2. **Study Module Documentation**

```bash
# Read module README
cat modules/container-app/README.md

# Review input validation
grep -A 5 "validation" modules/container-app/variables.tf
```

3. **Deploy Using Module**

```bash
cd lab3.1

terraform init
terraform plan
terraform apply
```

4. **Test Deployed Applications**

```bash
# Get all app URLs
terraform output simple_app_url
terraform output configured_app_url
terraform output secure_app_url
terraform output high_perf_app_url

# Test each app
curl $(terraform output -raw simple_app_url)
curl $(terraform output -raw configured_app_url)
curl $(terraform output -raw secure_app_url)
```

5. **View Module Outputs**

```bash
# See all configurations
terraform output all_apps_configuration
```

6. **Test Input Validation**

```bash
# Try invalid CPU value
cat > test-validation.tf <<EOF
module "invalid_app" {
  source = "./modules/container-app"
  
  name = "test"
  resource_group_name = "test"
  container_app_environment_id = "test"
  cpu = 3.0  # Invalid - should fail
}
EOF

terraform validate  # Should show validation error
rm test-validation.tf
```

### Expected Results
- ✅ Reusable module created
- ✅ 5 apps deployed using module
- ✅ Input validation working
- ✅ Comprehensive outputs
- ✅ Module documentation complete

### Cleanup
```bash
terraform destroy
```

---

## Lab 3.2: Module Composition

**Objective:** Compose multiple modules to build a complete application stack.

### Steps

1. **Understand Architecture**

```bash
cd ~/terraform-labs/lab3.2

# View architecture
terraform output architecture_diagram
```

2. **Review Module Dependencies**

```bash
# Check dependency graph
terraform graph | dot -Tsvg > architecture.svg
```

3. **Deploy Full Stack**

```bash
terraform init
terraform plan
terraform apply
```

4. **Verify Infrastructure**

```bash
# List all resources
az resource list \
  --resource-group rg-app-stack-dev \
  --output table

# Check networking
terraform output network_info

# Check monitoring
terraform output monitoring

# Check application URLs
terraform output application_urls
```

5. **Test Application Stack**

```bash
# Test frontend
curl $(terraform output -json application_urls | jq -r '.frontend')

# Test backend
curl $(terraform output -json application_urls | jq -r '.backend')

# Test API gateway
curl $(terraform output -json application_urls | jq -r '.api_gateway')
```

6. **View Module Composition**

```bash
# See how modules work together
terraform output lab_completion
```

### Expected Results
- ✅ Complete application stack deployed
- ✅ Multiple modules composed
- ✅ Shared infrastructure
- ✅ Proper module dependencies
- ✅ Data flow between modules

### Cleanup
```bash
terraform destroy
```

---

## Lab 4.1: Secure Container App with Key Vault

**Objective:** Deploy Container App with Azure Key Vault integration and Managed Identity.

### Steps

1. **Deploy Infrastructure**

```bash
cd ~/terraform-labs/lab4.1

terraform init
terraform plan
terraform apply

# Note: RBAC propagation may take 60 seconds
```

2. **Verify Key Vault**

```bash
# List secrets
KV_NAME=$(terraform output -raw key_vault_name)
az keyvault secret list --vault-name $KV_NAME --output table

# View secret (requires permissions)
az keyvault secret show \
  --vault-name $KV_NAME \
  --name database-connection-string \
  --query value -o tsv
```

3. **Verify Managed Identity**

```bash
# Check identity details
terraform output managed_identity

# Verify RBAC assignments
az role assignment list \
  --scope $(terraform output -json | jq -r '.key_vault_uri.value' | sed 's|https://||' | xargs -I {} az keyvault show --name {} --query id -o tsv)
```

4. **Test Container App**

```bash
# Get app URL
APP_URL=$(terraform output -raw container_app_url)
curl $APP_URL

# Check logs
az containerapp logs show \
  --name ca-secure-keyvault \
  --resource-group rg-containerapp-secure \
  --type console \
  --follow
```

5. **Verify Secret References**

```bash
# View container app configuration
az containerapp show \
  --name ca-secure-keyvault \
  --resource-group rg-containerapp-secure \
  --query "properties.configuration.secrets" \
  -o json
```

6. **Check Audit Logs**

```bash
# Query Key Vault audit logs
az monitor log-analytics query \
  --workspace $(terraform output -json | jq -r '.monitoring.log_analytics_workspace_id') \
  --analytics-query "AzureDiagnostics | where ResourceType == 'VAULTS' | take 10"
```

### Expected Results
- ✅ Key Vault with 4 secrets
- ✅ Managed Identity configured
- ✅ RBAC assignments in place
- ✅ Container App accessing secrets
- ✅ Audit logging enabled
- ✅ No secrets in Terraform state

### Cleanup
```bash
terraform destroy
```

---

## Lab 4.2: Network-Isolated Container App

**Objective:** Deploy Container Apps with VNet integration and network isolation.

### Steps

1. **Deploy Network Infrastructure**

```bash
cd ~/terraform-labs/lab4.2

terraform init
terraform plan
terraform apply
```

2. **Verify Network Configuration**

```bash
# View VNet details
az network vnet show \
  --name vnet-containerapp \
  --resource-group rg-containerapp-network \
  --query "{name:name, addressSpace:addressSpace}" \
  -o json

# List subnets
az network vnet subnet list \
  --vnet-name vnet-containerapp \
  --resource-group rg-containerapp-network \
  --output table

# Check NSG rules
az network nsg rule list \
  --nsg-name nsg-container-apps \
  --resource-group rg-containerapp-network \
  --output table
```

3. **Test External App (Should Work)**

```bash
# Get external app URL
EXTERNAL_URL=$(terraform output -json container_apps | jq -r '.external')
curl $EXTERNAL_URL
```

4. **Test Internal App (Should Fail from Internet)**

```bash
# This should timeout/fail
INTERNAL_FQDN=$(terraform output -json container_apps | jq -r '.internal' | sed 's/http:\/\///' | sed 's/ (internal only)//')
curl --connect-timeout 5 http://$INTERNAL_FQDN || echo "Expected: Internal app not accessible from internet"
```

5. **Verify Private Endpoint**

```bash
# Check private endpoint
az network private-endpoint show \
  --name pe-storage \
  --resource-group rg-containerapp-network \
  --query "{name:name, subnet:subnet.id}" \
  -o json

# Verify private DNS zone
az network private-dns zone show \
  --name privatelink.blob.core.windows.net \
  --resource-group rg-containerapp-network
```

6. **View Network Architecture**

```bash
# Display architecture diagram
terraform output network_architecture
```

7. **Test Inter-App Communication**

```bash
# External app should be able to call internal app
# Check external app logs
az containerapp logs show \
  --name ca-external-service \
  --resource-group rg-containerapp-network \
  --type console \
  --tail 50
```

### Expected Results
- ✅ VNet with dedicated subnets
- ✅ Container Apps in delegated subnet
- ✅ NSG rules configured
- ✅ Internal app not externally accessible
- ✅ External app publicly accessible
- ✅ Private endpoint for storage
- ✅ Private DNS zones configured

### Cleanup
```bash
terraform destroy
```

---

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. State Lock Conflicts

**Problem:** "Error acquiring the state lock"

**Solution:**
```bash
# List locks
az storage blob list \
  --account-name YOUR_STORAGE_ACCOUNT \
  --container-name tfstate \
  --output table

# Force unlock (use with caution)
terraform force-unlock LOCK_ID
```

#### 2. RBAC Propagation Delays

**Problem:** "Forbidden" errors with Key Vault or other resources

**Solution:**
```bash
# Wait 60-90 seconds after RBAC assignments
# Or add time_sleep resource in Terraform
```

#### 3. Container App Environment Subnet Requirements

**Problem:** "Subnet must be at least /23"

**Solution:**
```bash
# Use /23 or larger subnet
# Example: 10.0.0.0/23 provides 512 IPs
```

#### 4. Module Not Found

**Problem:** "Module not installed"

**Solution:**
```bash
# Initialize modules
terraform init

# Update modules
terraform get -update
```

#### 5. Validation Errors

**Problem:** "Invalid value for variable"

**Solution:**
```bash
# Check validation rules
grep -A 5 "validation" modules/*/variables.tf

# Ensure values match constraints
```

#### 6. Network Connectivity Issues

**Problem:** Container App can't reach internal services

**Solution:**
```bash
# Check NSG rules
# Verify subnet delegation
# Check private DNS configuration
# Verify VNet integration
```

### Useful Commands

```bash
# Check Terraform version
terraform version

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Show current state
terraform show

# List resources
terraform state list

# View specific resource
terraform state show RESOURCE_NAME

# Check for drift
terraform plan -refresh-only

# Import existing resource
terraform import RESOURCE_NAME AZURE_RESOURCE_ID

# Generate dependency graph
terraform graph | dot -Tsvg > graph.svg
```

### Azure CLI Helpers

```bash
# List Container Apps
az containerapp list --output table

# Show Container App details
az containerapp show --name NAME --resource-group RG

# View Container App logs
az containerapp logs show --name NAME --resource-group RG --type console

# Update Container App
az containerapp update --name NAME --resource-group RG --min-replicas 2

# List revisions
az containerapp revision list --name NAME --resource-group RG

# Deactivate revision
az containerapp revision deactivate --name REVISION_NAME --app NAME --resource-group RG
```

---

## Additional Resources

### Documentation
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Azure Container Apps Documentation](https://learn.microsoft.com/en-us/azure/container-apps/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)

### Tools
- [Terraform Language Server](https://github.com/hashicorp/terraform-ls)
- [tflint](https://github.com/terraform-linters/tflint)
- [checkov](https://www.checkov.io/)
- [terraform-docs](https://terraform-docs.io/)

### Community
- [HashiCorp Discuss](https://discuss.hashicorp.com/)
- [Terraform Registry](https://registry.terraform.io/)
- [Azure Container Apps Community](https://techcommunity.microsoft.com/t5/apps-on-azure-blog/bg-p/AppsonAzureBlog)

---

## Lab Completion Checklist

- [ ] Lab 1.1: Remote State Configuration
- [ ] Lab 1.2: Multi-Environment Workspaces
- [ ] Lab 2.1: Dynamic Configuration
- [ ] Lab 2.2: for_each Iteration
- [ ] Lab 3.1: Reusable Module Creation
- [ ] Lab 3.2: Module Composition
- [ ] Lab 4.1: Key Vault Integration
- [ ] Lab 4.2: Network Isolation

## Feedback

Please provide feedback on this training:
- What worked well?
- What could be improved?
- Additional topics you'd like to see?

---

**Training Version:** 1.0  
**Last Updated:** February 2026  
**Maintained by:** DevOps Training Team
