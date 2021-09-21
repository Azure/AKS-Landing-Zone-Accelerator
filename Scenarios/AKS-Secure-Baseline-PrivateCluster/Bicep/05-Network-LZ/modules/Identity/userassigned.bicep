param basename string

resource azidentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${basename}identity'
  location: resourceGroup().location
}

output identityid string = azidentity.id
output clientId string = azidentity.properties.clientId
output principalId string = azidentity.properties.principalId
