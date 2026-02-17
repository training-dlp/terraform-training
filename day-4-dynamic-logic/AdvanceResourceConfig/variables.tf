# Lab 3.1: Creating a Container App Module
# This creates a reusable module for Azure Container Apps

# File: modules/container-app/variables.tf

variable "name" {
  description = "Name of the container app"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]{0,30}[a-z0-9])?$", var.name))
    error_message = "Name must be lowercase alphanumeric, can contain hyphens, 2-32 chars, and start/end with alphanumeric."
  }
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "container_app_environment_id" {
  description = "ID of the Container App Environment"
  type        = string
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "main"
}

variable "cpu" {
  description = "CPU cores allocated to container (0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0)"
  type        = number
  default     = 0.5
  
  validation {
    condition     = contains([0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], var.cpu)
    error_message = "CPU must be one of: 0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0."
  }
}

variable "memory" {
  description = "Memory allocated to container (e.g., '0.5Gi', '1Gi', '2Gi')"
  type        = string
  default     = "1Gi"
  
  validation {
    condition     = can(regex("^[0-9]+(\\.[0-9]+)?Gi$", var.memory))
    error_message = "Memory must be in format like '0.5Gi', '1Gi', '2Gi'."
  }
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 1
  
  validation {
    condition     = var.min_replicas >= 0 && var.min_replicas <= 30
    error_message = "Min replicas must be between 0 and 30."
  }
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
  
  validation {
    condition     = var.max_replicas >= 1 && var.max_replicas <= 30
    error_message = "Max replicas must be between 1 and 30."
  }
}

variable "revision_mode" {
  description = "Revision mode: Single or Multiple"
  type        = string
  default     = "Single"
  
  validation {
    condition     = contains(["Single", "Multiple"], var.revision_mode)
    error_message = "Revision mode must be 'Single' or 'Multiple'."
  }
}

variable "ingress_enabled" {
  description = "Enable ingress for the container app"
  type        = bool
  default     = true
}

variable "external_enabled" {
  description = "Enable external ingress (requires ingress_enabled = true)"
  type        = bool
  default     = true
}

variable "target_port" {
  description = "Target port for ingress traffic"
  type        = number
  default     = 80
  
  validation {
    condition     = var.target_port > 0 && var.target_port <= 65535
    error_message = "Target port must be between 1 and 65535."
  }
}

variable "environment_variables" {
  description = "Environment variables for the container"
  type = map(object({
    name        = string
    value       = optional(string)
    secret_name = optional(string)
  }))
  default = {}
}

variable "secrets" {
  description = "Secrets for the container app"
  type = map(object({
    name  = string
    value = string
  }))
  default   = {}
  sensitive = true
}

variable "registry_server" {
  description = "Container registry server (e.g., myregistry.azurecr.io)"
  type        = string
  default     = ""
}

variable "registry_username" {
  description = "Container registry username"
  type        = string
  default     = ""
  sensitive   = true
}

variable "registry_password" {
  description = "Container registry password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dapr_enabled" {
  description = "Enable Dapr for the container app"
  type        = bool
  default     = false
}

variable "dapr_app_id" {
  description = "Dapr application ID"
  type        = string
  default     = ""
}

variable "dapr_app_port" {
  description = "Port that Dapr will proxy traffic to"
  type        = number
  default     = 3000
}

variable "enable_http_scale_rule" {
  description = "Enable HTTP-based scaling rule"
  type        = bool
  default     = true
}

variable "http_concurrent_requests" {
  description = "Number of concurrent requests for HTTP scaling"
  type        = number
  default     = 10
}

variable "health_check_path" {
  description = "Path for health checks"
  type        = string
  default     = "/health"
}

variable "enable_health_probes" {
  description = "Enable liveness and readiness probes"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
