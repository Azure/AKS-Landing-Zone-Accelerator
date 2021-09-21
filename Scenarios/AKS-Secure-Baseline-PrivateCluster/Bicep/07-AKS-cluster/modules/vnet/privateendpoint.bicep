param privateEndpointName string
param subnetid object
param privateLinkServiceConnections array
param location string = resourceGroup().location

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: subnetid
    privateLinkServiceConnections: privateLinkServiceConnections
  }
}

output privateEndpointName string = privateEndpoint.name
