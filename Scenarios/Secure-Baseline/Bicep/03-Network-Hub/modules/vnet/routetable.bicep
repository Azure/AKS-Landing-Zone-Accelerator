param rtName string
param location string = resourceGroup().location

resource rt 'Microsoft.Network/routeTables@2021-02-01' = {
  name: rtName
  location: location
}
output routetableID string = rt.id
