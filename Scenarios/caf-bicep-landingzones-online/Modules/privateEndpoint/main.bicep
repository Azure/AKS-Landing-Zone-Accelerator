param resourceType string
param resourceName string
param subnetId string
param groupId string

resource privateEndpointName_resource 'Microsoft.Network/privateEndpoints@2019-04-01'  = {
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

resource privateDNSZone_name 'Microsoft.Network/privateDnsZones@2018-09-01'  = {
  scope: resourceGroup(,  )
  name: privateDNSZone_name_var

 
}

resource privateDNSZone_name_vnetName_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' existing = {
  scope: resourceGroup(,  )
  name: '${}'
}
