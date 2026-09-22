output "cosmos_db_resource_id" {
  description = "The resource ID of the CosmosDB account."
  value       = azurerm_cosmosdb_account.cosmos.id
}

output "redis_cache_resource_id" {
  description = "The resource ID of the Redis cache."
  value       = module.redis.resource_id
}

output "resource_group_name" {
  description = "The resource group the PaaS ASE with CosmosDB Tier 4 was deployed into."
  value       = var.resource_group_name
}

// Outputs
output "vnet_resource_id" {
  description = "The resource ID of the virtual network."
  value       = azurerm_virtual_network.vnet.id
}
