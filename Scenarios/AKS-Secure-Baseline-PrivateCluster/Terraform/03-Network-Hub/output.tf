output "vnetHubName" {
  value = module.avm-res-network-virtualnetwork.name
}

output "rgHubName" {
  value = azurerm_resource_group.rg.name
}
