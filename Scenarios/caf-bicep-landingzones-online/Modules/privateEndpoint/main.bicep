param resourceType string
param resourceName string
param subnetId string
param groupId string
param dnsZoneName string


resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2019-04-01' = {
  name: '${resourceName}-privateEndpoint'
  location: resourceGroup().location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${resourceName}-privateEndpoint'
        properties: {
          privateLinkServiceId: resourceId(resourceType, resourceName)
          groupIds: [
            groupId
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

resource privateZone_resource 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZoneName
  location: 'global'
  tags: {}
  properties: {
    zoneType: 'Private'
    registrationVirtualNetworks: [
      {
        id: split(subnetId,'/subnets/')[0]
      }
    ]
    resolutionVirtualNetworks: [
      {
        id: split(subnetId,'/subnets/')[0]
      }
    ]
  }
}

resource vnetLink_resource 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}/${dnsZoneName}-link'
  tags: {}
  location: 'global'
  properties: {
    virtualNetwork: {
      id: split(subnetId,'/subnets/')[0]
    }
    registrationEnabled: true
  }
}
