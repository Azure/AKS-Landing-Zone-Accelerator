param hubNetwork object = {}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${hubNetwork.azureFirewall.name}-pip'
  location: hubNetwork.azureFirewall.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource hubfirewall 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: hubNetwork.azureFirewall.name
  location: hubNetwork.azureFirewall.location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf1'
        properties: {
          subnet: {
            id: resourceId('/resourceGroups/rg-hub-network/Microsoft.Network/virtualNetworks/subnets', 'hub-vnet', 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'appRc1'
        properties: {
          priority: 101
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'appRule1'
              protocols: [
                {
                  port: 80
                  protocolType: 'Http'
                }
              ]
              targetFqdns: [
                'www.microsoft.com'
              ]
              sourceAddresses: [
                '10.0.0.0/24'
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'netRc1'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'netRule1'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                '10.0.0.0/24'
              ]
              destinationAddresses: [
                '*'
              ]
              destinationPorts: [
                '8000-8999'
              ]
            }
          ]
        }
      }
    ]
  }
}
