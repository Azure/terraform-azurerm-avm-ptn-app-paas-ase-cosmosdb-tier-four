# Test-specific variables
variable "test_name" {
  type        = string
  description = "Name prefix for test resources"
  default     = "avmtest"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.test_name))
    error_message = "Test name must start and end with alphanumeric characters and can contain hyphens."
  }
}

variable "location" {
  type        = string
  description = "Azure region for test resources"
  default     = "East US"

  validation {
    condition = contains([
      "East US", "East US 2", "West US", "West US 2", "West US 3",
      "Central US", "South Central US", "North Central US", "West Central US",
      "Canada Central", "Canada East",
      "UK South", "UK West",
      "North Europe", "West Europe",
      "Australia East", "Australia Southeast",
      "Southeast Asia", "East Asia"
    ], var.location)
    error_message = "Location must be a valid Azure region that supports App Service Environment v3."
  }
}

variable "enable_telemetry" {
  type        = bool
  description = "Enable telemetry for the module"
  default     = false # Disabled for testing to avoid telemetry noise
}

# Override variables for testing specific scenarios
variable "test_scenario" {
  type        = string
  description = "Test scenario to run (basic, premium, multi-region)"
  default     = "basic"

  validation {
    condition     = contains(["basic", "premium", "multi-region"], var.test_scenario)
    error_message = "Test scenario must be one of: basic, premium, multi-region."
  }
}

variable "cosmos_consistency_level_override" {
  type        = string
  description = "Override CosmosDB consistency level for testing"
  default     = "Session"

  validation {
    condition = contains([
      "Eventual", "Session", "BoundedStaleness", "Strong", "ConsistentPrefix"
    ], var.cosmos_consistency_level_override)
    error_message = "Consistency level must be one of: Eventual, Session, BoundedStaleness, Strong, ConsistentPrefix."
  }
}

variable "redis_sku_override" {
  type        = string
  description = "Override Redis SKU for testing"
  default     = "Premium"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.redis_sku_override)
    error_message = "Redis SKU must be one of: Basic, Standard, Premium."
  }
}

variable "asp_sku_override" {
  type        = string
  description = "Override App Service Plan SKU for testing"
  default     = "I1v2"

  validation {
    condition     = can(regex("^I[1-3]v[2]$", var.asp_sku_override))
    error_message = "App Service Plan SKU must be an Isolated v2 SKU (I1v2, I2v2, I3v2) for App Service Environment."
  }
}

# Network configuration overrides
variable "vnet_address_space_override" {
  type        = string
  description = "Override VNet address space for testing"
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vnet_address_space_override, 0))
    error_message = "VNet address space must be a valid CIDR block."
  }
}

variable "tags_override" {
  type        = map(string)
  description = "Additional tags to apply to test resources"
  default     = {}
}
