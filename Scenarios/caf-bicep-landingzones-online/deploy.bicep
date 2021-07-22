targetScope = 'subscription'

param VNets array = []
param DdosProtectionPlan object = {}
param resourceGroupNames array = []

/*module rg './Modules/resourceGroup/main.bicep' = [for rg in resourceGroupNames: {
  name: rg
  params: {
    rg: rg
  }
}]*/

module Ddos './Modules/DdosProtectionPlans/main.bicep' = {
  name: 'DdosDeploy'
  scope: resourceGroup(DdosProtectionPlan.rg)
  params: {
    DdosProtectionPlan: DdosProtectionPlan
  }
}

module VNet './Modules/virtualNetwork/main.bicep' = [for VNet in VNets: {
  name: 'VNetDeploy'
  scope: resourceGroup(VNet.rg)
  params: {
    VNet: VNet
  }
}]
