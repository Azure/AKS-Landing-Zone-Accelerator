//param hubNetwork object = {}

resource Vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: ''
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        ''
      ]
    }
    subnets: [
      {
        name: ''
        properties: {
          addressPrefix: ''
        }
      }
    ]
    dhcpOptions: {
      dnsServers: [
        ''
      ]
    }
  }
}
