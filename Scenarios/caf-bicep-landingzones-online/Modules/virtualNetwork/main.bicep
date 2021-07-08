var vnets = [
  {
    name: 'vnet_hub_re1'
    rg: 'rg1'
    addressPrefix: '100.64.100.0/22'
    subnets: [
      {
      name: 'subnet1'
      addressPrefix: '100.64.100.0/27'
      }
      {
      name: 'subnet2'
      addressPrefix: '100.64.100.32/27'
      }
    ]
  }
]

resource vNetName_resource 'Microsoft.Network/virtualNetworks@2020-08-01' = [for vnet in vnets: {
  name: vnet.name
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet.addressPrefix
      ]
    }
    subnets: [for item in vnet.subnets: {
      name: item.name
      properties: {
        addressPrefix: item.addressPrefix
      }
    }]
  }
}]
