# Test infrastructure outputs
output "test_resource_group_name" {
  description = "The name of the test resource group"
  value       = azurerm_resource_group.test.name
}

output "test_resource_group_id" {
  description = "The ID of the test resource group"
  value       = azurerm_resource_group.test.id
}

output "test_deployment_name" {
  description = "The name used for the test deployment"
  value       = var.test_name
}

output "test_suffix" {
  description = "The random suffix used for the test"
  value       = random_string.suffix.result
}

output "test_location" {
  description = "The location used for the test"
  value       = var.location
}

output "test_scenario" {
  description = "The test scenario that was executed"
  value       = var.test_scenario
}

# Module outputs - these verify that the module is working correctly
output "module_cosmos_db_resource_id" {
  description = "The resource ID of the CosmosDB account from the module"
  value       = module.test_ptn_app_paas_ase_cosmosdb.cosmos_db_resource_id
}

output "module_redis_cache_resource_id" {
  description = "The resource ID of the Redis cache from the module"
  value       = module.test_ptn_app_paas_ase_cosmosdb.redis_cache_resource_id
}

output "module_vnet_resource_id" {
  description = "The resource ID of the virtual network from the module"
  value       = module.test_ptn_app_paas_ase_cosmosdb.vnet_resource_id
}

output "module_resource_group_name" {
  description = "The resource group name returned by the module"
  value       = module.test_ptn_app_paas_ase_cosmosdb.resource_group_name
}

# Validation outputs for testing
output "validation_cosmos_db_exists" {
  description = "Validates that CosmosDB resource ID is not empty"
  value       = length(module.test_ptn_app_paas_ase_cosmosdb.cosmos_db_resource_id) > 0
}

output "validation_redis_cache_exists" {
  description = "Validates that Redis cache resource ID is not empty"
  value       = length(module.test_ptn_app_paas_ase_cosmosdb.redis_cache_resource_id) > 0
}

output "validation_vnet_exists" {
  description = "Validates that VNet resource ID is not empty"
  value       = length(module.test_ptn_app_paas_ase_cosmosdb.vnet_resource_id) > 0
}

output "validation_resource_group_matches" {
  description = "Validates that the module uses the provided resource group"
  value       = module.test_ptn_app_paas_ase_cosmosdb.resource_group_name == azurerm_resource_group.test.name
}

# Summary output for easy validation
output "test_summary" {
  description = "Summary of the test execution"
  value = {
    test_name           = var.test_name
    test_scenario       = var.test_scenario
    location            = var.location
    resource_group      = azurerm_resource_group.test.name
    suffix              = random_string.suffix.result
    cosmos_db_created   = length(module.test_ptn_app_paas_ase_cosmosdb.cosmos_db_resource_id) > 0
    redis_cache_created = length(module.test_ptn_app_paas_ase_cosmosdb.redis_cache_resource_id) > 0
    vnet_created        = length(module.test_ptn_app_paas_ase_cosmosdb.vnet_resource_id) > 0
    all_validations_passed = (
      length(module.test_ptn_app_paas_ase_cosmosdb.cosmos_db_resource_id) > 0 &&
      length(module.test_ptn_app_paas_ase_cosmosdb.redis_cache_resource_id) > 0 &&
      length(module.test_ptn_app_paas_ase_cosmosdb.vnet_resource_id) > 0 &&
      module.test_ptn_app_paas_ase_cosmosdb.resource_group_name == azurerm_resource_group.test.name
    )
  }
}
