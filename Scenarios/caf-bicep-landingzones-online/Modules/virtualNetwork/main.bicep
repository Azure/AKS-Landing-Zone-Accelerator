param VNet object = {}

resource VNets_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: VNet.name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        VNet.addressPrefix
      ]
    }
    subnets: [for item in VNet.subnets: {
      name: item.name
      properties: {
        addressPrefix: item.addressPrefix
      }
    }]
    dhcpOptions: {
      dnsServers: [
        VNet.dnsServers
      ]
    }
  }
}
