param resourceType string
param resourceName string
param subnetId string
param groupId string

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
