targetScope = 'subscription'

// Parameters
param rgName string
param vnetHubName string
param hubVNETaddPrefixes array
param hubSubnets array
param azfwName string
param rtVMSubnetName string
param fwapplicationRuleCollections array
param fwnetworkRuleCollections array
param fwnatRuleCollections array
param location string = deployment().location
param availabilityZones array

module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: location
  }
}

module vnethub 'modules/vnet/vnet.bicep' = {
  scope: resourceGroup(rg.name)
  name: vnetHubName
  params: {
    location: location
    vnetAddressSpace: {
        addressPrefixes: hubVNETaddPrefixes
    }
    vnetName: vnetHubName
    subnets: hubSubnets
  }
  dependsOn: [
    rg
  ]
}

module publicipfw 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-PIP'
  params: {
    availabilityZones:availabilityZones
    location: location
    publicipName: 'AZFW-PIP'
    publicipproperties: {
      publicIPAllocationMethod: 'Static'
    }
    publicipsku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

resource subnetfw 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnethub.name}/AzureFirewallSubnet'
}

module azfirewall 'modules/vnet/firewall.bicep' = {
  scope: resourceGroup(rg.name)
  name: azfwName
  params: {
    availabilityZones: availabilityZones
    location: location
    fwname: azfwName
    fwipConfigurations: [
      {
        name: 'AZFW-PIP'
        properties: {
          subnet: {
            id: subnetfw.id
          }
          publicIPAddress: {
            id: publicipfw.outputs.publicipId
          }
        }
      }
    ]
    fwapplicationRuleCollections: fwapplicationRuleCollections
    fwnatRuleCollections: fwnatRuleCollections
    fwnetworkRuleCollections: fwnetworkRuleCollections
  }
}

module publicipbastion 'modules/VM/publicip.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'publicipbastion'
  params: {
    location: location
    publicipName: 'bastion-pip'
    publicipproperties: {
      publicIPAllocationMethod: 'Static'
    }
    publicipsku: {
      name: 'Standard'
      tier: 'Regional'
    }
  }
}

resource subnetbastion 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnethub.name}/AzureBastionSubnet'
}

module bastion 'modules/VM/bastion.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'bastion'
  params: {
    location: location
    bastionpipId: publicipbastion.outputs.publicipId
    subnetId: subnetbastion.id
  }
}

module routetable 'modules/vnet/routetable.bicep' = {
  scope: resourceGroup(rg.name)
  name: rtVMSubnetName
  params: {
    location: location
    rtName: rtVMSubnetName
  }
}

module routetableroutes 'modules/vnet/routetableroutes.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'vm-to-internet'
  params: {
    routetableName: routetable.name
    routeName: 'vm-to-internet'
    properties: {
      nextHopType: 'VirtualAppliance'
      nextHopIpAddress: azfirewall.outputs.fwPrivateIP
      addressPrefix: '0.0.0.0/0'
    }
  }
}
