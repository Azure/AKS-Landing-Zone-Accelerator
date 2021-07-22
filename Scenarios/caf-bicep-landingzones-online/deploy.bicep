targetScope = 'subscription'

param VNets array = []
param DdosProtectionPlan object = {}
param rgnames array = []
param rglocation string = ''

module rg './Modules/resourceGroup/main.bicep' = [for rg in rgnames: {
  name: rg
  params: {
    rg: rg
    location:rglocation
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
