param dnsZoneName string

resource privateZone_resource 'Microsoft.Network/dnsZones@2018-05-01'  = {
  name: dnsZoneName
  location: 'global'
  tags: {}
  properties: {
    zoneType: 'Private'
    registrationVirtualNetworks: [
      
    ]
    resolutionVirtualNetworks: [
     
    ]
  }
}
