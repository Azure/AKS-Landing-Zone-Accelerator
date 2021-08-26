@minLength(5)
@maxLength(50)
@description('Name of the azure container registry (must be globally unique)')
param acrName string

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
@description('Tier of your Azure Container Registry.')
param acrSku string = 'Standard'

param dnsZoneName string = 'privatelink.vaultcore.azure.net'

param subnetId string=''

// azure container registry
resource acr 'Microsoft.ContainerRegistry/registries@2019-12-01-preview' = {
  name: acrName
  location: location
  tags: {
   
  }
  sku: {
    name: acrSku
  }
  properties: {
    adminUserEnabled: false
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
  name: '${acrName}-privateEndpoint'
  location: resourceGroup().location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${acrName}-privateEndpoint'
        properties: {
          privateLinkServiceId:acr.id
          groupIds: [
            'registry'
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
