param identityName string
param location string = resourceGroup().location

resource azidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: identityName
  location: location
}

output identityid string = azidentity.id
output clientId string = azidentity.properties.clientId
output principalId string = azidentity.properties.principalId
