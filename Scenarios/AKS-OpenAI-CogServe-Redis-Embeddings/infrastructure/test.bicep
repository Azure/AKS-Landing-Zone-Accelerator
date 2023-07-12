param location string = resourceGroup().location

resource embeddingapp 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'xxaaaid-embedinging'
  location: location
}

resource fedCreds 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'string'
  parent: embeddingapp
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: 'http'
    subject: 'system:serviceaccount:default:serversa'
  }
}
