targetScope = 'subscription'
param rg object = {}
resource symbolicname 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rg.resourceGroupNames
  location: rg.location
  tags: {}
  properties: {
  }
}
