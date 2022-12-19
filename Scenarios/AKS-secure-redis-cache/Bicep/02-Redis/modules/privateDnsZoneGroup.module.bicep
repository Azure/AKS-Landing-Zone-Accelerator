
@description('Required. Name of the private dns zone.')
param privateDnsZoneName string

@description('Required. The private dns zone resource id')
param privateDnsZoneResourceId string

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name:'${privateDnsZoneName}/${privateDnsZoneName}-group'
  properties: {
    privateDnsZoneConfigs:[
      {
        properties: {
          privateDnsZoneId: privateDnsZoneResourceId
        }
      }
    ]
  }
}

output id string = privateDnsZoneGroup.id
