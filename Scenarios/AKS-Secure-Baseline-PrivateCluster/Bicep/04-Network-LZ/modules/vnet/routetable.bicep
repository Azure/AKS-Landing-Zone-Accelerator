param rtName string
param location string = resourceGroup().location

resource rt 'Microsoft.Network/routeTables@2020-11-01' = {
  name: rtName
  location: location
}
output routetableID string = rt.id
