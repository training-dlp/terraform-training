variable "st_name" {
  type        = string
  description = "Base name for the storage account (will be sanitized)"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "tier" {
  type    = string
  default = "Standard"
}

variable "env" {
  type        = string
  description = "Environment tag (dev, prod, etc.)"
}
