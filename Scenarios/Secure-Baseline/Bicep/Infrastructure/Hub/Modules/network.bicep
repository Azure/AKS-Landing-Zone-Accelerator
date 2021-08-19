param hubNetwork object = {}

resource VNet_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: hubNetwork.virtualNetwork.name
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


