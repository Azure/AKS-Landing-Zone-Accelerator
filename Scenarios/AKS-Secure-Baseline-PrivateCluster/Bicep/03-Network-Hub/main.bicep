targetScope = 'subscription'

// Parameters
param rgName string
param vnetHubName string
param hubVNETaddPrefixes array
param azfwName string
param rtVMSubnetName string
param fwapplicationRuleCollections array
param fwnetworkRuleCollections array
param fwnatRuleCollections array
param location string = deployment().location
param availabilityZones array
param defaultSubnetName string
param defaultSubnetAddressPrefix string
param azureFirewallSubnetName string
param azureFirewallSubnetAddressPrefix string
param azureFirewallManagementSubnetName string
param azureFirewallManagementSubnetAddressPrefix string
param azureBastionSubnetName string
param azureBastionSubnetAddressPrefix string
param vmsubnetSubnetName string
param vmsubnetSubnetAddressPrefix string

module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: vnetHubName
  params: {
    addressPrefixes: hubVNETaddPrefixes
    name: vnetHubName
    location: location
    subnets: [
      {
        name: defaultSubnetName
        addressPrefix: defaultSubnetAddressPrefix
      }
      {
        name: azureFirewallSubnetName
        addressPrefix: azureFirewallSubnetAddressPrefix
      }
      {
        name: azureFirewallManagementSubnetName
        addressPrefix: azureFirewallManagementSubnetAddressPrefix
      }
      {
        name: azureBastionSubnetName
        addressPrefix: azureBastionSubnetAddressPrefix
      }
      {
        name: vmsubnetSubnetName
        addressPrefix: vmsubnetSubnetAddressPrefix
      }
    ]
    enableTelemetry: true
  }
}

module publicIpFW 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-PIP'
  params: {
    name: 'AZFW-PIP'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicIpFWMgmt 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-Management-PIP'
  params: {
    name: 'AZFW-Management-PIP'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicipbastion 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'publicipbastion'
  params: {
    name: 'publicipbastion'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: 'bastion'
  params: {
    name: 'bastion'
    vNetId: virtualNetwork.outputs.resourceId
    bastionSubnetPublicIpResourceId: publicipbastion.outputs.resourceId
    location: location
    enableTelemetry: true
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.2.2' = {
  scope: resourceGroup(rg.name)
  name: rtVMSubnetName
  params: {
    name: rtVMSubnetName
    location: location
    routes: [
      {
        name: 'vm-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: azureFirewall.outputs.privateIp
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}


module azureFirewall 'br/public:avm/res/network/azure-firewall:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: azfwName
  params: {
    name: azfwName
    location: location
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    zones: availabilityZones
    publicIPResourceID: publicIpFW.outputs.resourceId
    managementIPResourceID: publicIpFWMgmt.outputs.resourceId
    applicationRuleCollections: fwapplicationRuleCollections
    natRuleCollections: fwnatRuleCollections
    networkRuleCollections: fwnetworkRuleCollections
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
