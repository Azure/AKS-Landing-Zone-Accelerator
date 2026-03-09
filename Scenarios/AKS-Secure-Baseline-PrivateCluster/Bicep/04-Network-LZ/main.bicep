targetScope = 'subscription'

param rgName string
param vnetSpokeName string
param spokeVNETaddPrefixes array
param rtAKSSubnetName string
param firewallIP string
param vnetHubName string
param appGatewayName string
param vnetHUBRGName string
param nsgAKSName string
param nsgAppGWName string
param rtAppGWSubnetName string
param enablePrivateCluster bool = true
param location string = deployment().location
param availabilityZones array
param appGwyAutoScale object
param securityRules array = []
param spokeSubnetDefaultPrefix string = '10.1.0.0/24'
param spokeSubnetAKSPrefix string = '10.1.1.0/24'
param spokeSubnetAppGWPrefix string = '10.1.2.0/27'
param spokeSubnetVMPrefix string = '10.1.3.0/24'
param spokeSubnetPLinkervicePrefix string = '10.1.4.0/24'
param remotePeeringName string = 'spoke-hub-peering'
param vmSize string = 'Standard_DS2_v2'

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

module rg 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module vnetspoke 'br/public:avm/res/network/virtual-network:0.7.2' = {
  scope: resourceGroup(rg.name)
  name: vnetSpokeName
  params: {
    addressPrefixes: spokeVNETaddPrefixes
    name: vnetSpokeName
    location: location
    subnets: [
      {
        name: 'default'
        addressPrefix: spokeSubnetDefaultPrefix
      }
      {
        name: 'AKS'
        addressPrefix: spokeSubnetAKSPrefix
        routeTableResourceId: routeTable.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroupAKS.outputs.resourceId
      }
      {
        name: 'AppGWSubnet'
        addressPrefix: spokeSubnetAppGWPrefix
        networkSecurityGroupResourceId: networkSecurityGroupAppGwy.outputs.resourceId
      }
      {
        name: 'vmsubnet'
        addressPrefix: spokeSubnetVMPrefix
      }
      {
        name: 'servicespe'
        addressPrefix: spokeSubnetPLinkervicePrefix
      }
    ]
    enableTelemetry: true
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: remotePeeringName
        remoteVirtualNetworkResourceId: vnethub.id
        useRemoteGateways: false
      }
    ]
  }
  dependsOn: [
    appGwyRouteTable
  ]
}

module networkSecurityGroupAKS 'br/public:avm/res/network/network-security-group:0.5.2' = {
  scope: resourceGroup(rg.name)
  name: nsgAKSName
  params: {
    name: nsgAKSName
    location: location
    securityRules: securityRules
    enableTelemetry: true
  }
}

module networkSecurityGroupAppGwy 'br/public:avm/res/network/network-security-group:0.5.2' = {
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

module routeTable 'br/public:avm/res/network/route-table:0.5.0' = {
  scope: resourceGroup(rg.name)
  name: rtAKSSubnetName
  params: {
    name: rtAKSSubnetName
    location: location
    routes: [
      {
        name: 'vm-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewallIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
    enableTelemetry: true
  }
}

module appGwyRouteTable 'br/public:avm/res/network/route-table:0.5.0' = {
  scope: resourceGroup(rg.name)
  name: rtAppGWSubnetName
  params: {
    name: rtAppGWSubnetName
    location: location
    routes: [
      {
        name: 'vm-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'Internet'
        }
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneACR 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsACRZone'
  params: {
    name: 'privatelink${environment().suffixes.acrLoginServer}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnethub.id
      }
      {
        virtualNetworkResourceId: vnetspoke.outputs.resourceId
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneKV 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsKVZone'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnethub.id
      }
      {
        virtualNetworkResourceId: vnetspoke.outputs.resourceId
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneSA 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
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

module privateDnsZoneAKS 'br/public:avm/res/network/private-dns-zone:0.8.1' = if (enablePrivateCluster) {
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

module publicIpAppGwy 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  scope: resourceGroup(rg.name)
  name: 'APPGW-PIP'
  params: {
    name: 'APPGW-PIP'
    location: location
    availabilityZones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module appgw 'br/public:avm/res/network/application-gateway:0.9.0' = {
  scope: resourceGroup(rg.name)
  name: 'appgw'
  params: {
    name: appGatewayName
    location: location
    sku: 'Standard_v2'
    autoscaleMinCapacity: appGwyAutoScale.minCapacity
    autoscaleMaxCapacity: appGwyAutoScale.maxCapacity
    availabilityZones: availabilityZones
    gatewayIPConfigurations: [
      {
        name: 'appgw-ip-configuration'
        properties: {
          subnet: {
            id: vnetspoke.outputs.subnetResourceIds[2]
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIpAppGwy.outputs.resourceId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'HTTP-80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'aksAppRoutingPool'
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backend-http-settings'
        properties: {
          cookieBasedAffinity: 'Disabled'
          path: '/'
          port: 80
          protocol: 'Http'
          requestTimeout: 60
        }
      }
    ]
    httpListeners: [
      {
        name: 'httplistener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'HTTP-80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'httplistener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'aksAppRoutingPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'backend-http-settings')
          }
        }
      }
    ]
    enableTelemetry: true
  }
}

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.5.0' = {
  scope: resourceGroup(rg.name)
  name: 'aksIdentity'
  params: {
    name: 'aksIdentity'
    location: location
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
  scope: resourceGroup(rg.name)
  name: 'virtualMachineDeployment'
  params: {
    // Required parameters
    adminUsername: 'azureuser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'jumpbox'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            pipConfiguration: {
              name: 'pip-01'
            }
            subnetResourceId: vnetspoke.outputs.subnetResourceIds[3]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: vmSize
    availabilityZone: 1
    // Non-required parameters
    disablePasswordAuthentication: false
    adminPassword: 'Password123'
    location: location
  }
}
