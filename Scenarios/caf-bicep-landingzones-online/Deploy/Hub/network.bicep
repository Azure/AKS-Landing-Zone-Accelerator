param hubNetwork object = {}

resource hubVnet 'Microsoft.Network/virtualNetworks@2020-06-01' = if (hubNetwork.virtualNetwork.deploy) {
  name: hubNetwork.virtualNetwork.VnetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubNetwork.virtualNetwork.addressPrefix
      ]
    }
    subnets: [for item in hubNetwork.virtualNetwork.subnets: {
      name: item.name
      properties: {
        addressPrefix: item.addressPrefix
      }
    }]
    dhcpOptions: {
      dnsServers: [
        hubNetwork.virtualNetwork.dnsServers
      ]
    }
  }
}
