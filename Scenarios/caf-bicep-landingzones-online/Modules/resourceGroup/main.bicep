targetScope = 'subscription'
param rg string = ''
param location string= ''
resource symbolicname 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: rg
  location: location
  tags: {}
  properties: {
  }
}
