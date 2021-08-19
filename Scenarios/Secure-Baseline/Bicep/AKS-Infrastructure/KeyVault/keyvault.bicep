param vaultName string = 'keyVault${uniqueString(resourceGroup().id)}' // must be globally unique
param location string = resourceGroup().location
param sku string = 'Standard'
param tenant string = '' // replace with your tenantId
param enabledForDeployment bool = true
param enabledForTemplateDeployment bool = true
param enabledForDiskEncryption bool = true
param enableRbacAuthorization bool = false
param softDeleteRetentionInDays int = 90

param dnsZoneName string = 'privatelink.vaultcore.azure.net'

param subnetId string=''






resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: vaultName
  location: location
  properties: {
    tenantId: tenant
    sku: {
      family: 'A'
      name: sku
    }
    enabledForDeployment: enabledForDeployment
    enabledForDiskEncryption: enabledForDiskEncryption
    enabledForTemplateDeployment: enabledForTemplateDeployment
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enableRbacAuthorization: enableRbacAuthorization
  }
}

resource privateDNSZone 'Microsoft.Network/dnsZones@2018-05-01'  = {
  name: dnsZoneName
  location: 'global'
  tags: {}
  properties: {
    zoneType: 'Private'
    registrationVirtualNetworks: [
      
    ]
    resolutionVirtualNetworks: [
     
    ]
  }
}

resource vnetLink_resource 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDNSZone.name}/link_to_${split(split(subnetId,'/subnets/')[0],'/')[-1]}'
  tags: {}
  location: 'global'
  properties: {
    virtualNetwork: {
      id: split(subnetId,'/subnets/')[0]
    }
    registrationEnabled: true
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2019-04-01' = {
  name: '${vaultName}-privateEndpoint'
  location: resourceGroup().location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${vaultName}-privateEndpoint'
        properties: {
          privateLinkServiceId: keyvault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]

    manualPrivateLinkServiceConnections: []
    subnet: {
      id: subnetId
    }
  }
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: '${privateEndpoint.name}/vault-PrivateDnsZoneGroup'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dnsConfig'
        properties: {
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
}
