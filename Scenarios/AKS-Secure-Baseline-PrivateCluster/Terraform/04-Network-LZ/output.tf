output "speSubnetId" {
  value = module.avm-res-network-vnet-spe-subnet.resource_id
}

output "dnszoneAkvId" {
  value = module.avm-res-network-privatednszone-akv.resource_id
}

output "dnszoneAcrId" {
  value = module.avm-res-network-privatednszone-acr.resource_id
}

output "vnetLzId" {
  value = module.avm-res-network-vnet.resource_id
}

output "snetAksId" {
  value = module.avm-res-network-vnet-aks-subnet.resource_id
}

output "dnszoneAksId" {
  value = module.avm-res-network-privatednszone-aks.resource_id
}

output "dnszoneContosoId" {
  value = module.avm-res-network-privatednszone-contoso.resource_id
}

output "rgLzName" {
  value = azurerm_resource_group.rg.name 
}

output "vnetLzName" {
  value = module.avm-res-network-vnet.vnet.name 
}