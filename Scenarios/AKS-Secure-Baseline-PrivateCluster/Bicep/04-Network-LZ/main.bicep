targetScope = 'subscription'

// Parameters
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
param dhcpOptions object
param location string = deployment().location

module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

module vnetspoke 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: vnetSpokeName
  params: {
    location: location
    vnetAddressSpace: {
      addressPrefixes: spokeVNETaddPrefixes
    }
    vnetName: vnetSpokeName
    subnets: spokeSubnets
    dhcpOptions: dhcpOptions
  }
  dependsOn: [
    rg
  ]
}

module nsgakssubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(rg.name)
  name: nsgAKSName
  params: {
    location: location
    nsgName: nsgAKSName
  }
}

module routetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: rtAKSSubnetName
  params: {
    location: location
    rtName: rtAKSSubnetName
  }
}

module routetableroutes 'modules/vnet/routetableroutes.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aks-to-internet'
  params: {
    routetableName: rtAKSSubnetName
    routeName: 'AKS-to-internet'
    properties: {
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: firewallIP
      addressPrefix: '0.0.0.0/0'
    }
  }
  dependsOn: [
    routetable
  ]
}

resource vnethub 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
  scope: resourceGroup(vnetHUBRGName)
  name: vnetHubName
}

module vnetpeeringhub 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(vnetHUBRGName)
  name: 'vnetpeeringhub'
  params: {
    peeringName: 'HUB-to-Spoke'
    vnetName: vnethub.name
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: vnetspoke.outputs.vnetId
      }
    }
  }
  dependsOn: [
    vnethub
    vnetspoke
  ]
}

module vnetpeeringspoke 'modules/vnet/vnetpeering.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vnetpeeringspoke'
  params: {
    peeringName: 'Spoke-to-HUB'
    vnetName: vnetspoke.outputs.vnetName
    properties: {
      allowVirtualNetworkAccess: true
      allowForwardedTraffic: true
      remoteVirtualNetwork: {
        id: vnethub.id
      }
    }
  }
  dependsOn: [
    vnethub
    vnetspoke
  ]
}

module privatednsACRZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsACRZone'
  params: {
    privateDNSZoneName: 'privatelink.azurecr.io'
  }
}

module privateDNSLinkACR 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkACR'
  params: {
    privateDnsZoneName: privatednsACRZone.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsVaultZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsVaultZone'
  params: {
    privateDNSZoneName: 'privatelink.vaultcore.azure.net'
  }
}

module privateDNSLinkVault 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkVault'
  params: {
    privateDnsZoneName: privatednsVaultZone.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module privatednsAKSZone 'modules/vnet/privatednszone.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsAKSZone'
  params: {
    privateDNSZoneName: 'privatelink.${toLower(location)}.azmk8s.io'
  }
}

module privateDNSLinkAKS 'modules/vnet/privatednslink.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'privateDNSLinkAKS'
  params: {
    privateDnsZoneName: privatednsAKSZone.outputs.privateDNSZoneName
    vnetId: vnethub.id
  }
}

module publicipappgw 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'APPGW-PIP'
  params: {
    location: location
    publicipName: 'APPGW-PIP'
    publicipproperties: {
      publicIPAllocationMethod: 'Static'
    }
    publicipsku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

resource appgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetSpokeName}/${appGatewaySubnetName}'
}

module appgw 'modules/vnet/appgw.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'appgw'
  params: {
    location: location
    appgwname: appGatewayName
    appgwpip: publicipappgw.outputs.publicipId
    subnetid: appgwSubnet.id
  }
}

module nsgappgwsubnet 'modules/vnet/nsg.bicep' = {
  scope: resourceGroup(rg.name)
  name: nsgAppGWName
  params: {
    location: location
    nsgName: nsgAppGWName
    securityRules: [
      {
        name: 'Allow443InBound'
        properties: {
          priority: 102
          sourceAddressPrefix: '*'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowControlPlaneV1SKU'
        properties: {
          priority: 110
          sourceAddressPrefix: 'GatewayManager'
          protocol: '*'
          destinationPortRange: '65503-65534'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowControlPlaneV2SKU'
        properties: {
          priority: 111
          sourceAddressPrefix: 'GatewayManager'
          protocol: '*'
          destinationPortRange: '65200-65535'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHealthProbes'
        properties: {
          priority: 120
          sourceAddressPrefix: 'AzureLoadBalancer'
          protocol: '*'
          destinationPortRange: '*'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

module appgwroutetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: rtAppGWSubnetName
  params: {
    location: location
    rtName: rtAppGWSubnetName
  }
}
