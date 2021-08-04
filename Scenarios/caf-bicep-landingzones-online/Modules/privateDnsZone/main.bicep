param dnsZoneName string
param vnetId string

resource privateZone_resource 'Microsoft.Network/dnsZones@2018-05-01' = {
  name: dnsZoneName
  location: 'global'
  tags: {}
  properties: {
    zoneType: 'Private'
    registrationVirtualNetworks: [
      {
        id: vnetId
      }
    ]
    resolutionVirtualNetworks: [
      {
        id: vnetId
      }
    ]
  }
}

resource vnetLink_resource 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}/${dnsZoneName}-link'
  tags: {}
  location: 'global'
  properties: {
    virtualNetwork: {
      id: 'string'
    }
    registrationEnabled: true
  }
}
