# Test Configuration for AVM Pattern Module

This directory contains test configurations for the Azure Verified Module (AVM) Pattern for App Service Environment with CosmosDB Tier 4.

## Overview

The test configuration validates the local module by deploying it with various scenarios and verifying that all components are created correctly.

## Test Structure

- `main.tf` - Main test configuration that calls the local module
- `variables.tf` - Test-specific variables and validation rules
- `outputs.tf` - Test outputs for validation and debugging
- `terraform.tfvars.example` - Example configuration file

## Test Scenarios

The test supports multiple scenarios:

### Basic (Default)

- Standard App Service Environment configuration
- Premium Redis cache (P1) - required for zones support
- Single-region CosmosDB
- Minimal resource allocation

### Premium

- Zone-redundant App Service Environment
- Premium Redis cache (P2) with higher capacity
- Enhanced CosmosDB throughput
- Higher worker count

### Multi-Region

- Multi-region CosmosDB with failover
- Bounded staleness consistency
- Cross-region replication testing

## Usage

1. **Copy the example variables file:**

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars with your preferred configuration:**

   ```hcl
   test_name        = "mytest"
   location         = "East US"
   test_scenario    = "basic"
   enable_telemetry = false
   ```

3. **Initialize Terraform:**

   ```bash
   $env:ARM_SUBSCRIPTION_ID = (az account show | convertFrom-Json).id
   terraform init
   ```

4. **Plan the deployment:**

   ```bash
   terraform plan -var="test_scenario=basic" -var="test_name=basictest"
   ```

5. **Apply the configuration:**

   ```bash
   terraform apply -var="test_scenario=basic" -var="test_name=basictest" --auto-approve
   ```

6. **Review the outputs for validation:**

   ```bash
   terraform output test_summary
   ```

7. **Clean up resources:**
   ```bash
   terraform destroy
   ```

## Variables

### Required Variables

- `test_name` - Name prefix for test resources
- `location` - Azure region for deployment

### Optional Variables

- `test_scenario` - Test scenario to execute (basic, premium, multi-region)
- `enable_telemetry` - Enable/disable telemetry (default: false for testing)
- `cosmos_consistency_level_override` - Override CosmosDB consistency level
- `redis_sku_override` - Override Redis SKU
- `asp_sku_override` - Override App Service Plan SKU
- `vnet_address_space_override` - Override VNet address space
- `tags_override` - Additional tags for resources

## Validation

The test configuration includes built-in validation:

1. **Resource Creation Validation** - Ensures all expected resources are created
2. **Configuration Validation** - Verifies that configuration parameters are applied correctly
3. **Output Validation** - Checks that module outputs are populated correctly
4. **Integration Validation** - Confirms that resources are properly integrated

## Expected Resources

The test will create:

- Resource Group (for test isolation)
- Virtual Network with subnets
- Network Security Groups (via AVM modules)
- App Service Environment v3
- App Service Plan (via AVM module)
- CosmosDB account with database and container
- Redis Cache (via AVM module)
- Private DNS zones
- Private endpoints for CosmosDB and Redis

## Troubleshooting

### Common Issues

1. **Import Conflicts - "resource already exists"**

   ```bash
   # Import existing resources before apply
   terraform import "module.test_ptn_app_paas_ase_cosmosdb.azurerm_app_service_environment_v3.ase" "/subscriptions/SUBSCRIPTION-ID/resourceGroups/RG-NAME/providers/Microsoft.Web/hostingEnvironments/ASE-NAME"

   terraform import "module.test_ptn_app_paas_ase_cosmosdb.azurerm_cosmosdb_account.cosmos" "/subscriptions/SUBSCRIPTION-ID/resourceGroups/RG-NAME/providers/Microsoft.DocumentDB/databaseAccounts/COSMOS-NAME"
   ```

2. **Redis Zones Error - "Feature zones requires a Premium sku"**

   - AVM Redis module automatically enables availability zones
   - Solution: Use Premium SKU (default in test configuration)
   - Alternative: Find AVM module parameter to disable zones

3. **Redis Capacity Error - "invalid combination of sku_name, family, and capacity"**

   - Premium Redis requires capacity 1+ (P1, P2, P3, P4, P5)
   - Basic scenario uses P1 (capacity=1), Premium scenario uses P2 (capacity=2)
   - Cannot use capacity 0 with Premium SKU

4. **App Service Environment Quota Error**

   - Error: "Current Limit (IsolatedV2 VMs): 0"
   - Solution: Request quota increase at <https://aka.ms/antquotahelp>
   - Required: Minimum 3 IsolatedV2 VMs for basic testing

5. **App Service Environment SKU Requirements**

   - Must use Isolated v2 SKUs (I1v2, I2v2, I3v2)
   - Standard or Basic SKUs will fail

6. **Location Support**

   - Not all Azure regions support App Service Environment v3
   - Use regions like East US, West US 2, North Europe, etc.

7. **Resource Quotas**

   - App Service Environment requires significant compute quotas
   - **IsolatedV2 VMs**: Default quota is often 0, requires increase
   - **Request quota increase**: Visit <https://aka.ms/antquotahelp>
   - **Minimum required**: 3 IsolatedV2 VMs for basic testing
   - Ensure your subscription has adequate limits

8. **Redis Cache Requirements**

   - AVM Redis module automatically enables availability zones
   - **Premium SKU required** for zones support (Basic/Standard will fail)
   - Default test configuration uses Premium SKU for compatibility

9. **Networking Requirements**
   - Ensure VNet address spaces don't conflict with existing networks
   - Private endpoint subnet must be different from ASE subnet

### Debugging

Enable detailed logging:

```bash
export TF_LOG=DEBUG
terraform apply
```

Check specific resource status:

```bash
terraform show | grep -A 10 "resource_type"
```

### Cost Considerations

App Service Environment v3 and associated resources can be expensive. Remember to:

- Use the basic test scenario for cost-effective testing
- Destroy resources immediately after testing
- Monitor costs in the Azure portal

## Example Test Execution

```bash
# Basic test
terraform apply -var="test_scenario=basic" -var="test_name=basictest"

# Premium test
terraform apply -var="test_scenario=premium" -var="test_name=premiumtest"

# Multi-region test
terraform apply -var="test_scenario=multi-region" -var="test_name=multiregiontest"
```

## Automated Testing

This configuration can be integrated into CI/CD pipelines for automated testing:

1. Use service principal authentication
2. Set variables via environment variables or pipeline variables
3. Use backend configuration for state management
4. Implement proper cleanup in failure scenarios
