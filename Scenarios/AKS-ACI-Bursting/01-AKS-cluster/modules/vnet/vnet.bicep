resource virtualNetwork_aks 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'demo-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.100.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'aci-subnet'
        properties: {
          addressPrefix: '10.100.0.0/24'
        }
      }
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: '10.100.1.0/24'
        }
      }
    ]
  }
}
