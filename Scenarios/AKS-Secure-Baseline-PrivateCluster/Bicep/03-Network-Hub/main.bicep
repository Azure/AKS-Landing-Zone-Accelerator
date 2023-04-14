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
    availabilityZones: availabilityZones
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

module publicipfwmanagement 'modules/vnet/publicip.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-Management-PIP'
  params: {
    availabilityZones:availabilityZones
    location: location
    publicipName: 'AZFW-Management-PIP'
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

resource subnetfwmanagement 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnethub.name}/AzureFirewallManagementSubnet'
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
    fwipManagementConfigurations: {
      name: 'AZFW-Management-PIP'
      properties: {
        subnet: {
          id: subnetfwmanagement.id
        }
        publicIPAddress: {
          id: publicipfwmanagement.outputs.publicipId
        }
      }
    }
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

//  Telemetry Deployment
@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true
var telemetryId = '0d807b2d-f7c3-4710-9a65-e88257df1ea0-${location}'
resource telemetrydeployment 'Microsoft.Resources/deployments@2021-04-01' = if (enableTelemetry) {
  name: telemetryId
  location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}
