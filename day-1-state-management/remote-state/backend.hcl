# Backend Configuration for Remote State
# 
# This file contains the configuration for storing Terraform state
# in Azure Storage with locking enabled.
#
# Usage:
#   terraform init -backend-config=backend.hcl
#
# Or update main.tf backend block and run:
#   terraform init -migrate-state

resource_group_name  = "rg-terraform-demo"
storage_account_name = "satfworkshop"
container_name       = "tfstate"
key                  = "day1-remote.tfstate"

# Optional: Subscription ID if different from default
# subscription_id = "00000000-0000-0000-0000-000000000000"

# Optional: Tenant ID if needed
# tenant_id = "00000000-0000-0000-0000-000000000000"
