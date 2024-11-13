output "vnetHubName" {
  value = module.avm-res-network-virtualnetwork.name
}

output "rgHubName" {
  value = azurerm_resource_group.rg.name
}

output "vnetHubId" {
  value = module.avm-res-network-virtualnetwork.resource_id
}

output "firewallPrivateIp" {
  value = module.avm-res-network-azurefirewall.resource.ip_configuration.0.private_ip_address
}
