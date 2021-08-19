param resourceType string
param resourceName string
param subnetId string
param groupId string
param dnsZoneresourceId string
param dnsZoneRGName string


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



resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpointName_resource.name}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: dnsZoneresourceId
        }
      }
    ]
  }
}

resource vnetLink_resource 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}/${split(split(subnetId,'/subnets/')[0],'/')[-1]}-link'
  tags: {}
  location: 'global'
  properties: {
    virtualNetwork: {
      id: split(subnetId,'/subnets/')[0]
    }
    registrationEnabled: true
  }
}
