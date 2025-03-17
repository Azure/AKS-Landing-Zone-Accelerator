// Parameters
param location string
param cosmosDbAccountName string
param virtualNetworkName string
param subnetName string
param rgSpokeName string = 'AKS-LZA-SPOKE-${location}'


resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {  
  scope: subscription()
  name: rgSpokeName
}


// Cosmos DB Account
resource cosmosDbAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDbAccountName
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    isVirtualNetworkFilterEnabled: true // Required for private link access
    publicNetworkAccess: 'Disabled' // Disable public access for security
  }
}

// Private Endpoint for Cosmos DB
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: '${cosmosDbAccountName}-privateEndpoint'
  location: location
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/VirtualNetworks/subnets', virtualNetworkName, subnetName)
    }
    privateLinkServiceConnections: [
      {
        name: 'MyConnection'
        properties: {
          privateLinkServiceId: cosmosDbAccount.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

// Output for verification
output cosmosDbId string = cosmosDbAccount.id
