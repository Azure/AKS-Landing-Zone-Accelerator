param privateEndpointName string
param subnetid string
param groupIds array
param resourceId string
param privatelinkConnName string

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: privateEndpointName
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnetid
    }
    privateLinkServiceConnections: [
      {
        name: privatelinkConnName
        properties: {
          groupIds: groupIds
          privateLinkServiceId: resourceId
        }
      }
    ]
  }
}

output privateEndpointName string = privateEndpoint.name
