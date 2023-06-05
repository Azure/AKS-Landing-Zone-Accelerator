##############
# CAF MODULE #
##############

module "CAFResourceNames" {
  source      = "../00-Naming-module"
  workload    = "rate"
  environment = "dev"
  region      = "eus"
  instance    = "001"
}

#############
# RESOURCES #
#############

# Resource Group for Hub
# ----------------------

resource "azurerm_resource_group" "rg" {
  name     = module.CAFResourceNames.names.azurerm_resource_group
  location = var.location
}

#############
## OUTPUTS ##
#############
# These outputs are used by later deployments

output "hub_rg_location" {
  value = azurerm_resource_group.rg.location
}

output "hub_rg_name" {
  value = azurerm_resource_group.rg.name
}



