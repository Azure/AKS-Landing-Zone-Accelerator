param publicipName string
param publicipsku object
param publicipproperties object
param location string = resourceGroup().location
param availabilityZones array

resource publicip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: publicipName
  location: location
  sku: publicipsku
  properties: publicipproperties
  zones: !empty(availabilityZones) ? availabilityZones : null
}
output publicipId string = publicip.id
