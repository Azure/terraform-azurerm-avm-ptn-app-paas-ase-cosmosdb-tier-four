terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    modtm = {
      source  = "azure/modtm"
      version = "~> 0.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "test" {
  name     = "${var.test_name}-rg-${random_string.suffix.result}"
  location = var.location
  tags = {
    environment = "test"
    purpose     = "avm-pattern-testing"
  }
}

module "test_ptn_app_paas_ase_cosmosdb" {
  source = "../"

  name                = var.test_name
  location            = var.location
  resource_group_name = azurerm_resource_group.test.name

  enable_telemetry                       = var.enable_telemetry
  vnet_address_prefix                    = var.vnet_address_space_override
  default_subnet_address_prefix          = cidrsubnet(var.vnet_address_space_override, 8, 1)
  private_endpoint_subnet_address_prefix = cidrsubnet(var.vnet_address_space_override, 8, 2)

  ase_custom_dns_suffix      = null
  ase_front_end_scale_factor = var.test_scenario == "premium" ? 25 : 15
  ase_zone_redundant         = var.test_scenario == "premium" ? true : false

  asp_os_type      = "Linux"
  asp_sku_name     = var.asp_sku_override
  asp_worker_count = var.test_scenario == "premium" ? 3 : 1

  cosmos_consistency_level    = var.cosmos_consistency_level_override
  cosmos_container_throughput = var.test_scenario == "premium" ? 1000 : 400
  cosmos_capabilities         = var.test_scenario == "premium" ? ["EnableServerless"] : []
  cosmos_geo_locations = var.test_scenario == "multi-region" ? [
    {
      location          = var.location
      failover_priority = 0
      zone_redundant    = false
    },
    {
      location          = var.location == "East US" ? "West US 2" : "East US"
      failover_priority = 1
      zone_redundant    = false
    }
  ] : []

  redis_capacity            = var.test_scenario == "premium" ? 2 : 1
  redis_enable_non_ssl_port = false
  redis_minimum_tls_version = "1.2"
  redis_sku_name            = var.redis_sku_override
  redis_version             = "6"
  redis_private_endpoints   = {}

  private_endpoints                       = {}
  private_endpoints_manage_dns_zone_group = true

  tags = merge({
    environment   = "test"
    purpose       = "avm-pattern-testing"
    module        = "avm-ptn-app-paas-ase-cosmosdb-tier-four"
    test_scenario = var.test_scenario
    test_run_id   = random_string.suffix.result
  }, var.tags_override)
}
