targetScope = 'subscription'
param spoke1rgnames array = []
param location string = ''
resource spoke1ResourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for rg in spoke1rgnames: {
  name: rg
  location: location
  tags: {}
  properties: {
  }
}]
