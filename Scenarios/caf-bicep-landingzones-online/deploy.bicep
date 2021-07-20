targetScope = 'subscription'

param VNets array = []

module VNet './Modules/virtualNetwork/main.bicep' = [for VNet in VNets: {
  name: 'VNetDeploy'
  scope: resourceGroup(VNet.rg)
  params: {
    VNet: VNet
  }
}]






