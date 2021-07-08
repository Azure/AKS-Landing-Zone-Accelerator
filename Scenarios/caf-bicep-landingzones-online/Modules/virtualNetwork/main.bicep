var vnets = [
  {
    name: 'vnet_hub_re1'
    rg: 'vnet_hub_re1'
    addressPrefix: '100.64.100.0/22'
    subnets: [
      {
      name: 'GatewaySubnet'
      addressPrefix: '100.64.100.0/27'
      }
      {
      name: 'AzureFirewallSubnet'
      addressPrefix: '100.64.101.0/26'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '100.64.101.64/26'
      }
      {
        name: 'jumpbox'
        addressPrefix: '100.64.102.0/27'
      }
      {
        name: 'private_endpoints'
        addressPrefix: '100.64.103.128/25'
      }
    ]
  }
  {
    name: 'aks'
    rg: 'aks_spoke_re1'
    addressPrefix: '10.100.80.0/22'
    subnets: [
      {
      name: 'aks_nodepool_system'
      addressPrefix: '10.100.80.0/24'
      }
      {
      name: 'aks_nodepool_user1'
      addressPrefix: '10.100.81.0/24'
      }
      {
        name: 'aks_ingress'
        addressPrefix: '10.100.82.0/24'
      }
      {
        name: 'jumpbox'
        addressPrefix: '10.100.83.64/28'
      }
      {
        name: 'private_endpoints'
        addressPrefix: '10.100.83.0/27'
      }
      {
        name: 'AzureBastionSubnet'
        addressPrefix: '10.100.83.32/27'
      }
      {
        name: 'agw'
        addressPrefix: '10.100.83.96/27'
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
