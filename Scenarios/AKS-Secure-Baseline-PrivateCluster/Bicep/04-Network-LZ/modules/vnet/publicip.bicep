param publicipName string
param publicipsku object
param publicipproperties object
param location string = resourceGroup().location
param availabilityZones array

resource publicip 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  name: publicipName
  location: location
  sku: publicipsku
  zones: !empty(availabilityZones) ? availabilityZones : null
  properties: publicipproperties
}
output publicipId string = publicip.id
