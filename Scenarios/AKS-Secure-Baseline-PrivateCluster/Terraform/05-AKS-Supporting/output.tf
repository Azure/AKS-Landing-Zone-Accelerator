output "acrName" {
  value = module.avm-res-containerregistry-registry.resource.name
}

output "akvName" {
  value = module.avm-res-keyvault-vault.resource.name
}

output "acrId" {
  value = module.avm-res-containerregistry-registry.resource_id
}

output "akvId" {
  value = module.avm-res-keyvault-vault.resource_id
}