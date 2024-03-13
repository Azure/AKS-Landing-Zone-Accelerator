targetScope = 'subscription'

param rgName string
param vnetSpokeName string
param spokeVNETaddPrefixes array
param spokeSubnets array
param rtAKSSubnetName string
param firewallIP string
param vnetHubName string
param appGatewayName string
param appGatewaySubnetName string
param vnetHUBRGName string
param nsgAKSName string
param nsgAppGWName string
param rtAppGWSubnetName string
param dnsServers array
param location string = deployment().location
param availabilityZones array
param appGwyAutoScale object
param securityRules array = []

var privateDNSZoneAKSSuffixes = {
  AzureCloud: '.azmk8s.io'
  AzureUSGovernment: '.cx.aks.containerservice.azure.us'
  AzureChinaCloud: '.cx.prod.service.azk8s.cn'
  AzureGermanCloud: '' //TODO: what is the correct value here?
}

resource vnethub 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(vnetHUBRGName)
  name: vnetHubName
}

resource appgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetSpokeName}/${appGatewaySubnetName}'
}

module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module vnetspoke 'br/public:avm/res/network/virtual-network:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: vnetSpokeName
  params: {
    addressPrefixes: spokeVNETaddPrefixes
    name: vnetSpokeName
    location: location
    subnets: spokeSubnets
    enableTelemetry: true
    dnsServers: dnsServers
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'spoke-hub-peering'
        remoteVirtualNetworkId: vnethub.id
        useRemoteGateways: false
      }
    ]
  }
}

module networkSecurityGroupAKS 'br/public:avm/res/network/network-security-group:0.1.3' = {
  scope: resourceGroup(rg.name)
  name: nsgAKSName
  params: {
    name: nsgAKSName
    location: location
    securityRules: securityRules
    enableTelemetry: true
  }
}

module networkSecurityGroupAppGwy 'br/public:avm/res/network/network-security-group:0.1.3' = {
  scope: resourceGroup(rg.name)
  name: nsgAppGWName
  params: {
    name: nsgAppGWName
    location: location
    securityRules: [
      {
        name: 'Allow443InBound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 102
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowControlPlaneV1SKU'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '65503-65534'
          direction: 'Inbound'
          priority: 110
          protocol: '*'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowControlPlaneV2SKU'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '65200-65535'
          direction: 'Inbound'
          priority: 111
          protocol: '*'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowHealthProbes'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
          direction: 'Inbound'
          priority: 120
          protocol: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
        }
      }
    ]
    enableTelemetry: true
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.2.2' = {
  scope: resourceGroup(rg.name)
  name: rtAKSSubnetName
  params: {
    name: rtAKSSubnetName
    location: location
    // routes: [
    //   {
    //     name: 'vm-to-internet'
    //     properties: {
    //       addressPrefix: '0.0.0.0/0'
    //       nextHopIpAddress: azureFirewall.outputs.ipConfiguration.properties.privateIPAddress
    //       nextHopType: 'VirtualAppliance'
    //       enableTelemetry: true
    //     }
    //   }
    // ]
    enableTelemetry: true
  }
}

module appGwyRouteTable 'br/public:avm/res/network/route-table:0.2.2' = {
  scope: resourceGroup(rg.name)
  name: rtAppGWSubnetName
  params: {
    name: rtAppGWSubnetName
    location: location
    // routes: [
    //   {
    //     name: 'vm-to-internet'
    //     properties: {
    //       addressPrefix: '0.0.0.0/0'
    //       nextHopIpAddress: azureFirewall.outputs.ipConfiguration.properties.privateIPAddress
    //       nextHopType: 'VirtualAppliance'
    //       enableTelemetry: true
    //     }
    //   }
    // ]
    enableTelemetry: true
  }
}

module privateDnsZoneACR 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsACRZone'
  params: {
    name: 'privatelink${environment().suffixes.acrLoginServer}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnethub.id
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneKV 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsKVZone'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnethub.id
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneSA 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsSAZone'
  params: {
    name: 'privatelink.file.${environment().suffixes.storage}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnethub.id
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneAKS 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsAKSZone'
  params: {
    name: 'privatelink.${toLower(location)}${privateDNSZoneAKSSuffixes[environment().name]}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnethub.id
      }
    ]
    enableTelemetry: true
  }
}

module publicIpAppGwy 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'APPGW-PIP'
  params: {
    name: 'APPGW-PIP'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

// app gateway module needs to go here


