targetScope = 'subscription'

param rgName string
param keyVaultPrivateEndpointName string
param acrPrivateEndpointName string
param saPrivateEndpointName string
param vnetName string
param subnetName string
param privateDNSZoneACRName string
param privateDNSZoneKVName string
param privateDNSZoneSAName string
param acrName string = 'eslzacr${uniqueString('acrvws',utcNow('u'))}'
param keyvaultName string = 'eslz-kv-${uniqueString('acrvws',utcNow('u'))}'
param storageAccountName string = 'eslzsa${uniqueString('aks',utcNow('u'))}'
param storageAccountType string
param location string = deployment().location

//var acrName = 'eslzacr${uniqueString(rgName, deployment().name)}'
//var keyvaultName = 'eslz-kv-${uniqueString(rgName, deployment().name)}'

module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

module acr 'modules/acr/acr.bicep' = {
  scope: resourceGroup(rg.name)
  name: acrName
  params: {
    location: location
    acrName: acrName
    acrSkuName: 'Premium'
  }
}

module keyvault 'modules/keyvault/keyvault.bicep' = {
  scope: resourceGroup(rg.name)
  name: keyvaultName
  params: {
    location: location
    keyVaultsku: 'Standard'
    name: keyvaultName
    tenantId: subscription().tenantId
  }
}

module storage 'modules/storage/storage.bicep' = {
  scope: resourceGroup(rg.name)
  name: storageAccountName
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountType: storageAccountType
  }
}

resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${subnetName}'
}

module privateEndpointKeyVault 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: keyVaultPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'Vault'
    ]
    privateEndpointName: keyVaultPrivateEndpointName
    privatelinkConnName: '${keyVaultPrivateEndpointName}-conn'
    resourceId: keyvault.outputs.keyvaultId
    subnetid: servicesSubnet.id
  }
}

module privateEndpointAcr 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: acrPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'registry'
    ]
    privateEndpointName: acrPrivateEndpointName
    privatelinkConnName: '${acrPrivateEndpointName}-conn'
    resourceId: acr.outputs.acrid
    subnetid: servicesSubnet.id
  }
}

module privateEndpointSA 'modules/vnet/privateendpoint.bicep' = {
  scope: resourceGroup(rg.name)
  name: saPrivateEndpointName
  params: {
    location: location
    groupIds: [
      'file'
    ]
    privateEndpointName: saPrivateEndpointName
    privatelinkConnName: '${saPrivateEndpointName}-conn'
    resourceId: storage.outputs.storageAccountId
    subnetid: servicesSubnet.id
  }
}

resource privateDNSZoneACR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneACRName
}

module privateEndpointACRDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'acr-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneACR.id
    privateEndpointName: privateEndpointAcr.name
  }
}

resource privateDNSZoneKV 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneKVName
}

module privateEndpointKVDNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'kv-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneKV.id
    privateEndpointName: privateEndpointKeyVault.name
  }
}

resource privateDNSZoneSA 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  scope: resourceGroup(rg.name)
  name: privateDNSZoneSAName
}

module privateEndpointSADNSSetting 'modules/vnet/privatedns.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'sa-pvtep-dns'
  params: {
    privateDNSZoneId: privateDNSZoneSA.id
    privateEndpointName: privateEndpointSA.name
  }
}

module aksIdentity 'modules/Identity/userassigned.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksIdentity'
  params: {
    location: location
    identityName: 'aksIdentity'
  }
}

output acrName string = acr.name
output keyvaultName string = keyvault.name
