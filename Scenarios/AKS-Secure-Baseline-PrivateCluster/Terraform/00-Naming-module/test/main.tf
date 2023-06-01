# CAF
module "CAFResourceNames" {
  source      = "../"
  workload    = "gsma"
  environment = "dev"
  region      = "weu"
  instance    = "001"
}

output "azurerm_route_table" {
  value = module.CAFResourceNames.names.azurerm_route_table
}

output "azurerm_firewall_policy_rule_collection_group" {
  value = module.CAFResourceNames.names.azurerm_firewall_policy_rule_collection_group
}

output "all_resources" {
  value = module.CAFResourceNames.names
}
