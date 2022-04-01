param nsgName string
param securityRules array = []
param location string = resourceGroup().location

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: securityRules
  }
}
output nsgID string = nsg.id
