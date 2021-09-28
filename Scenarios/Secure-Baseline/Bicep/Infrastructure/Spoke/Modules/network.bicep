param spoke1Network object = {}
param hubNetwork object = {}
param location string = resourceGroup().location
var routeTableName = 'route-to-${location}-hub-fw'

resource VNet_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: spoke1Network.virtualNetwork.name
  location: resourceGroup().location
  dependsOn: []
  properties: {
    addressSpace: {
      addressPrefixes: [
        spoke1Network.virtualNetwork.addressPrefix
      ]
    }
    subnets: [for item in spoke1Network.virtualNetwork.subnets: {
      name: item.name
      properties: {
        addressPrefix: item.addressPrefix
        /*networkSecurityGroup: {
          id: resourceId('Microsoft.Network/networkSecurityGroups', item.NSGName)
        }*/
      }
    }]
    dhcpOptions: {
      dnsServers: [
        spoke1Network.virtualNetwork.dnsServers
      ]
    }
  }
}

resource AKSNSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'aksilbs-nsg'
  location: resourceGroup().location
  properties: {
    securityRules: []
  }
}

resource appgwyNSG 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'appgwy-nsg'
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        'name': 'Allow443InBound'
        'properties': {
          'description': 'Allow ALL web traffic into 443.'
          'protocol': 'Tcp'
          'sourcePortRange': '*'
          'sourceAddressPrefix': 'Internet'
          'destinationPortRange': '443'
          'destinationAddressPrefix': 'VirtualNetwork'
          'access': 'Allow'
          'priority': 100
          'direction': 'Inbound'
        }
      }
      {
        'name': 'AllowControlPlaneInBound'
        'properties': {
          'description': 'Allow Azure Control Plane in. (https://docs.microsoft.com/azure/application-gateway/configuration-infrastructure#network-security-groups)'
          'protocol': '*'
          'sourcePortRange': '*'
          'sourceAddressPrefix': '*'
          'destinationPortRange': '65200-65535'
          'destinationAddressPrefix': '*'
          'access': 'Allow'
          'priority': 110
          'direction': 'Inbound'
        }
      }
      {
        'name': 'AllowHealthProbesInBound'
        'properties': {
          'description': 'Allow Azure Health Probes in. (https://docs.microsoft.com/azure/application-gateway/configuration-infrastructure#network-security-groups)'
          'protocol': '*'
          'sourcePortRange': '*'
          'sourceAddressPrefix': 'AzureLoadBalancer'
          'destinationPortRange': '*'
          'destinationAddressPrefix': 'VirtualNetwork'
          'access': 'Allow'
          'priority': 120
          'direction': 'Inbound'
        }
      }
      {
        'name': 'DenyAllInBound'
        'properties': {
          'protocol': '*'
          'sourcePortRange': '*'
          'sourceAddressPrefix': '*'
          'destinationPortRange': '*'
          'destinationAddressPrefix': '*'
          'access': 'Deny'
          'priority': 1000
          'direction': 'Inbound'
        }
      }
      {
        'name': 'AllowAllOutbound'
        'properties': {
          'protocol': '*'
          'sourcePortRange': '*'
          'sourceAddressPrefix': '*'
          'destinationPortRange': '*'
          'destinationAddressPrefix': '*'
          'access': 'Allow'
          'priority': 1000
          'direction': 'Outbound'
        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: spoke1Network.appGwyPIP.name
  location: resourceGroup().location
  sku: {
    name: spoke1Network.appGwyPIP.sku
  }
  properties: {
    publicIPAllocationMethod: spoke1Network.appGwyPIP.allocationMethod
    publicIPAddressVersion: spoke1Network.appGwyPIP.publicIPAddressVersion
  }
}

resource hubFirewall 'Microsoft.Network/azureFirewalls@2021-02-01' existing = {
  name: hubNetwork.azureFirewall.name
}

resource fwRouteTable 'Microsoft.Network/routeTables@2021-02-01' = {
  name: routeTableName
  location: location
  properties: {
    routes: [
      {
        name: 'r-nexthop-to-fw'
        properties: {
          addressPrefix: '0.0.0.0/0'
          //nextHopIpAddress: hubFirewall.properties.ipConfigurations[0].properties.privateIPAddress
          nextHopIpAddress: '1.1.1.1'
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}
  