variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "tfworkshop"

  validation {
    condition     = length(var.project_name) <= 10 && can(regex("^[a-z0-9]+$", var.project_name))
    error_message = "Project name must be lowercase alphanumeric and max 10 characters."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"

  validation {
    condition = contains([
      "eastus", "eastus2", "westus", "westus2", "westus3",
      "centralus", "northeurope", "westeurope", "southeastasia"
    ], var.location)
    error_message = "Location must be a valid Azure region."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "initial"

  validation {
    condition     = contains(["initial", "dev", "staging", "prod"], var.environment)
    error_message = "Environment must be initial, dev, staging, or prod."
  }
}

variable "container_app_cpu" {
  description = "CPU cores for container app"
  type        = number
  default     = 0.25

  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.container_app_cpu)
    error_message = "CPU must be a valid value (0.25, 0.5, 0.75, 1.0, etc.)."
  }
}

variable "container_app_memory" {
  description = "Memory for container app (e.g., 0.5Gi, 1Gi)"
  type        = string
  default     = "0.5Gi"

  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.container_app_memory))
    error_message = "Memory must be in format like 0.5Gi, 1Gi, 2Gi, etc."
  }
}

variable "min_replicas" {
  description = "Minimum number of container replicas"
  type        = number
  default     = 1

  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 30
    error_message = "Min replicas must be between 0 and 30."
  }
}

variable "max_replicas" {
  description = "Maximum number of container replicas"
  type        = number
  default     = 3

  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 30
    error_message = "Max replicas must be between 1 and 30."
  }
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
