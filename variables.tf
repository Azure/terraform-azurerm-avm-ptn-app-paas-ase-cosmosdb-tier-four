variable "name" {
  type        = string
  description = "Required. The name of the deployment."
}

variable "ase_custom_dns_suffix" {
  type        = string
  default     = null
  description = "Optional custom DNS suffix for the ASE (e.g. myname.appserviceenvironment.net)."
}

// ASE (App Service Environment) settings
variable "ase_front_end_scale_factor" {
  type        = number
  default     = 15
  description = "Front end scale factor for the ASE (maps to ASE network configuration frontEndScaleFactor where supported)."
}

variable "ase_zone_redundant" {
  type        = bool
  default     = false
  description = "Whether ASE should be zone redundant (where supported)."
}

// App Service Plan (asp) settings
variable "asp_os_type" {
  type        = string
  default     = "Linux"
  description = "OS type for App Service Plan module."
}

variable "asp_sku_name" {
  type        = string
  default     = "S1"
  description = "SKU name for App Service Plan"
}

variable "asp_worker_count" {
  type        = number
  default     = 1
  description = "Worker count for the App Service Plan where applicable."
}

variable "cosmos_capabilities" {
  type        = list(string)
  default     = []
  description = "List of CosmosDB capabilities to enable (e.g. [\"EnableServerless\"])."
}

// CosmosDB specific variables
variable "cosmos_consistency_level" {
  type        = string
  default     = "Session"
  description = "Consistency level for the CosmosDB account (e.g., Session, BoundedStaleness)."
}

variable "cosmos_container_throughput" {
  type        = number
  default     = 400
  description = "Throughput for the default Cosmos DB SQL container."
}

variable "cosmos_geo_locations" {
  type = list(object({
    location          = string
    failover_priority = number
    zone_redundant    = optional(bool, false)
  }))
  default     = []
  description = "Geo locations for CosmosDB account. A list of objects { location, failover_priority, zone_redundant }."
}

variable "cosmos_max_interval_in_seconds" {
  type        = number
  default     = null
  description = "When using BoundedStaleness consistency this sets the maximum interval in seconds."
}

variable "cosmos_max_staleness_prefix" {
  type        = number
  default     = null
  description = "When using BoundedStaleness consistency this sets the maximum staleness prefix."
}

variable "default_subnet_address_prefix" {
  type        = string
  default     = "192.168.250.0/24"
  description = "Optional. Default subnet address prefix."
}

// Variables converted from main.bicep
variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "location" {
  type        = string
  default     = null
  description = "Optional. Location for all resources. If null, consumers should pass a value."
}

variable "private_endpoint_subnet_address_prefix" {
  type        = string
  default     = "192.168.251.0/24"
  description = "Optional. PrivateEndpoint subnet address prefix."
}

# Allow consumers to provide additional private endpoint definitions. The module will merge
# any consumer-provided endpoints with the endpoints created in this module (CosmosDB + Redis).
variable "private_endpoints" {
  type        = map(any)
  default     = {}
  description = "Optional map of additional private endpoints. The module will merge these with the endpoints it creates for CosmosDB and Redis."
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "When true the module will create the private_dns_zone_group block in the private endpoint."
}

variable "redis_capacity" {
  type        = number
  default     = 0
  description = "Redis capacity (0..6 for Basic/Standard)."
}

variable "redis_enable_non_ssl_port" {
  type        = bool
  default     = false
  description = "Expose whether to enable non-SSL port for Redis."
}

variable "redis_minimum_tls_version" {
  type        = string
  default     = "1.2"
  description = "Minimum TLS version for Redis."
}

variable "redis_private_endpoints" {
  type        = map(any)
  default     = {}
  description = "A map of private endpoints for Redis to pass into the Redis AVM module (mergeable with module-generated endpoints)."
}

// Redis settings (expose AVM module inputs)
variable "redis_sku_name" {
  type        = string
  default     = "Basic"
  description = "Redis SKU name"
}

variable "redis_version" {
  type        = string
  default     = "6"
  description = "Redis version (string)."
}

variable "resource_group_name" {
  type        = string
  default     = null
  description = "Optional. Resource group name where resources are deployed."
}

variable "suffix" {
  type        = string
  default     = null
  description = "Optional. Suffix for all resources."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Optional. Tags to apply to resources."
}

variable "vnet_address_prefix" {
  type        = string
  default     = "192.168.250.0/23"
  description = "Optional. Virtual Network address space."
}
