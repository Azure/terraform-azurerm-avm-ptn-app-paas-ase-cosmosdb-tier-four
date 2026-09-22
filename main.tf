// Main Terraform resources converted from main.bicep

# If the caller did not provide a suffix, create a short random id
resource "random_id" "suffix" {
  count = var.suffix == null ? 1 : 0

  byte_length = 4
}

locals {
  name_prefix = var.name
  suffix      = var.suffix != null ? var.suffix : (random_id.suffix[0].hex)
}

// Network Security Groups via AVM modules
module "default_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  location            = var.location
  name                = "${var.name}-default-nsg-${local.suffix}"
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags
}

module "private_endpoint_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"

  location            = var.location
  name                = "${var.name}-privateendpointsubnet-nsg-${local.suffix}"
  resource_group_name = var.resource_group_name
  enable_telemetry    = var.enable_telemetry
  tags                = var.tags
}

// Virtual Network + Subnets
resource "azurerm_virtual_network" "vnet" {
  location            = var.location
  name                = "${var.name}-vNet-${local.suffix}"
  resource_group_name = var.resource_group_name
  address_space       = [var.vnet_address_prefix]
  tags                = var.tags
}

resource "azurerm_subnet" "default" {
  address_prefixes                  = [var.default_subnet_address_prefix]
  name                              = "default"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies = "Disabled"

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.Web/hostingEnvironments"
    }
  }
}

resource "azurerm_subnet" "private_endpoint_subnet" {
  address_prefixes                  = [var.private_endpoint_subnet_address_prefix]
  name                              = "PrivateEndpointSubnet"
  resource_group_name               = var.resource_group_name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  private_endpoint_network_policies = "Disabled"
}

// Associate NSGs to subnets
resource "azurerm_subnet_network_security_group_association" "default_assoc" {
  network_security_group_id = module.default_nsg.resource_id
  subnet_id                 = azurerm_subnet.default.id
}

resource "azurerm_subnet_network_security_group_association" "private_endpoint_assoc" {
  network_security_group_id = module.private_endpoint_nsg.resource_id
  subnet_id                 = azurerm_subnet.private_endpoint_subnet.id
}

// Private DNS Zones
resource "azurerm_private_dns_zone" "appservice" {
  name                = "${var.name}.appserviceenvironment.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "cosmosdb" {
  name                = "privatelink.documents.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone" "redis" {
  name                = "privatelink.redis.cache.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

// Virtual network links for private DNS zones
resource "azurerm_private_dns_zone_virtual_network_link" "appservice_vnet_link" {
  name                  = "vnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.appservice.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "cosmosdb_vnet_link" {
  name                  = "vnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.cosmosdb.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

resource "azurerm_private_dns_zone_virtual_network_link" "redis_vnet_link" {
  name                  = "vnetlink"
  private_dns_zone_name = azurerm_private_dns_zone.redis.name
  resource_group_name   = var.resource_group_name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

// App Service Environment (minimal representation)
resource "azurerm_app_service_environment_v3" "ase" {
  name                = "${var.name}-${local.suffix}"
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.default.id
  tags                = var.tags
}

// App Service Plan - use AVM serverfarm module when available
module "asp" {
  source = "Azure/avm-res-web-serverfarm/azurerm"

  location                   = var.location
  name                       = "${var.name}-asp-${local.suffix}"
  os_type                    = var.asp_os_type
  resource_group_name        = var.resource_group_name
  app_service_environment_id = azurerm_app_service_environment_v3.ase.id
  enable_telemetry           = var.enable_telemetry
  sku_name                   = var.asp_sku_name
  tags                       = var.tags
  worker_count               = var.asp_worker_count
}

// CosmosDB account (native azurerm resource)
resource "azurerm_cosmosdb_account" "cosmos" {
  location            = var.location
  name                = "${var.name}-cosmos-${local.suffix}"
  offer_type          = "Standard"
  resource_group_name = var.resource_group_name
  kind                = "GlobalDocumentDB"
  tags                = var.tags

  consistency_policy {
    consistency_level       = var.cosmos_consistency_level
    max_interval_in_seconds = try(var.cosmos_max_interval_in_seconds, null)
    max_staleness_prefix    = try(var.cosmos_max_staleness_prefix, null)
  }
  dynamic "geo_location" {
    for_each = length(var.cosmos_geo_locations) > 0 ? var.cosmos_geo_locations : [
      {
        location          = var.location
        failover_priority = 0
        zone_redundant    = false
      }
    ]

    content {
      failover_priority = geo_location.value.failover_priority
      location          = geo_location.value.location
      zone_redundant    = lookup(geo_location.value, "zone_redundant", false)
    }
  }
}

// Cosmos DB SQL database and container
resource "azurerm_cosmosdb_sql_database" "db" {
  account_name        = azurerm_cosmosdb_account.cosmos.name
  name                = "${var.name}-cosmosdb"
  resource_group_name = var.resource_group_name
}

resource "azurerm_cosmosdb_sql_container" "container" {
  account_name        = azurerm_cosmosdb_account.cosmos.name
  database_name       = azurerm_cosmosdb_sql_database.db.name
  name                = "defaultContainer"
  partition_key_paths = ["/partitionKey"]
  resource_group_name = var.resource_group_name
  throughput          = var.cosmos_container_throughput
}

// Redis Cache via AVM module
module "redis" {
  source = "Azure/avm-res-cache-redis/azurerm"

  location            = var.location
  name                = "${var.name}-redis-${local.suffix}"
  resource_group_name = var.resource_group_name
  capacity            = var.redis_capacity
  enable_non_ssl_port = var.redis_enable_non_ssl_port
  enable_telemetry    = var.enable_telemetry
  minimum_tls_version = var.redis_minimum_tls_version
  private_endpoints = merge(var.redis_private_endpoints, {
    redis_pe = {
      name                          = "${var.name}-ReddisPrivateEndpoint-${local.suffix}"
      subnet_resource_id            = azurerm_subnet.private_endpoint_subnet.id
      private_dns_zone_resource_ids = toset([azurerm_private_dns_zone.redis.id])
      custom_network_interface_name = "${var.name}-ReddisPrivateEndpoint-nic-${local.suffix}"
    }
  })
  redis_version = var.redis_version
  sku_name      = var.redis_sku_name
  tags          = var.tags
}

// Build private endpoints map (merge user-provided with the module-created endpoints)
locals {
  builtin_private_endpoints = {
    "cosmosdb" = {
      location                       = var.location
      name                           = "${var.name}-CosmosPrivateEndpoint-${local.suffix}"
      resource_group_name            = var.resource_group_name
      subnet_resource_id             = azurerm_subnet.private_endpoint_subnet.id
      private_connection_resource_id = azurerm_cosmosdb_account.cosmos.id
      subresource_names              = ["Sql"]
      private_dns_zone_resource_ids  = [azurerm_private_dns_zone.cosmosdb.id]
      network_interface_name         = "${var.name}-CosmosPrivateEndpoint-nic-${local.suffix}"
      ip_configurations = [
        {
          name               = "default"
          private_ip_address = "192.168.251.4"
          member_name        = null
          subresource_name   = null
        }
      ]
      tags = var.tags
    }
    "redis" = {
      location                       = var.location
      name                           = "${var.name}-ReddisPrivateEndpoint-${local.suffix}"
      resource_group_name            = var.resource_group_name
      subnet_resource_id             = azurerm_subnet.private_endpoint_subnet.id
      private_connection_resource_id = module.redis.resource_id
      subresource_names              = ["redisCache"]
      private_dns_zone_resource_ids  = [azurerm_private_dns_zone.redis.id]
      network_interface_name         = "${var.name}-ReddisPrivateEndpoint-nic-${local.suffix}"
      ip_configurations              = []
      tags                           = var.tags
    }
  }
  private_endpoints = merge(var.private_endpoints, local.builtin_private_endpoints)
}




