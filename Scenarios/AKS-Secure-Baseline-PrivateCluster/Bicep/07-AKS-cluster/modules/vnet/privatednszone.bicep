param privateDNSZoneName string

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSZoneName
  location: 'global'
}

output privateDNSZoneName string = privateDNSZone.name
output privateDNSZoneId string = privateDNSZone.id
