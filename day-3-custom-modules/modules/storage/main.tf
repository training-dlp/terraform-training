locals {
  clean_name = substr(replace(lower("${var.st_name}${var.env}"), "-", ""), 0, 24)
}

resource "azurerm_storage_account" "storage" {
  name                     = local.clean_name
  resource_group_name      = "rg-terraform-demo"
  location                 = var.location
  account_tier             = var.tier
  account_replication_type = var.env == "prod" ? "GRS" : "LRS" # Conditional logic!

  tags = {
    Environment = var.env
  }
}
