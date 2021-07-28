targetScope = 'subscription'

param VNets array = []
param DdosProtectionPlan object = {}
param rgnames array = []
param acr object = {}
param networkSecurityGroups array = []
param trafficAnalytics object = {}

module rg './Modules/resourceGroup/main.bicep' = [for rg in rgnames: {
  name: rg
  params: {
    rg: rg
    location: deployment().location
  }
}]

module Ddos './Modules/DdosProtectionPlans/main.bicep' = {
  name: 'DdosDeploy'
  scope: resourceGroup(DdosProtectionPlan.rg)
  params: {
    DdosProtectionPlan: DdosProtectionPlan
  }
  dependsOn:[
    rg
  ]
}

module VNet './Modules/virtualNetwork/main.bicep' = [for VNet in VNets: {
  name: 'VNetDeploy'
  scope: resourceGroup(VNet.rg)
  params: {
    VNet: VNet
  }
  dependsOn: [
    Ddos
  ]
}]

module ACR './Modules/ACR/main.bicep' = {
  name: 'ACRDeploy'
  scope: resourceGroup(acr.rg)
  params: {
    acrName: acr.name
    acrSku: acr.sku
  }
  dependsOn:[
    rg
  ]
}

module NSG './Modules/networkSecurityGroup/main.bicep' = [for NSG in networkSecurityGroups: {
  name: 'NSGDeploy'
  scope: resourceGroup(NSG.rg)
  params: {
    networkSecurityGroup: NSG
  }
  dependsOn:[
    rg
  ]
}]
