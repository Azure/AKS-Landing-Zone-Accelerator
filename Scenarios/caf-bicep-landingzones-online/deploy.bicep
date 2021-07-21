targetScope = 'subscription'

param VNets array = []
param DdosProtectionPlan object = {}

module Ddos './Modules/DdosProtectionPlans/main.bicep' = {
  name: 'DdosDeploy'
  scope: resourceGroup(DdosProtectionPlan.rg)
  params: {
  }
}

/*module VNet './Modules/virtualNetwork/main.bicep' = [for VNet in VNets: {
  name: 'VNetDeploy'
  scope: resourceGroup(VNet.rg)
  params: {
    VNet: VNet
  }
}]
*/






