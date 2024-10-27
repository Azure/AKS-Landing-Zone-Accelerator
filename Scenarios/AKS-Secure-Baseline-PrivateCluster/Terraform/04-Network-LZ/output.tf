output "speSubnetId" {
  value = module.avm-res-network-vnet-spe-subnet.resource_id
}

output "privateDnsZoneAkvId" {
  value = module.avm-res-network-privatednszone-akv.resource_id
}

output "privateDnsZoneAcrId" {
  value = module.avm-res-network-privatednszone-acr.resource_id
}