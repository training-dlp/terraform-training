variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "learning"
}

variable "enable_versioning" {
  description = "Enable blob versioning for state backup"
  type        = bool
  default     = true
}
