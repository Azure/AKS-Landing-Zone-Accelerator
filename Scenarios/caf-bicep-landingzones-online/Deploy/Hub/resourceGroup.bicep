targetScope = 'subscription'
param hubrgnames array = []
param location string = ''
resource hubResourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for rg in hubrgnames: {
  name: rg
  location: location
  tags: {}
  properties: {
  }
}]
