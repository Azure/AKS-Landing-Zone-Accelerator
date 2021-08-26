targetScope = 'subscription'
param hubrgnames array = []
param location string = ''
param hubNetwork object = {}

/*module hubRG '../Modules/resourceGroup.bicep' = {
  name: 'hubRGDeploy'
  params: {
    hubrgnames:hubrgnames
    location:location
  }
}*/

module hubVNet '../Modules/network.bicep' = {
  scope: resourceGroup(hubNetwork.virtualNetwork.rg)
  name: 'hubNetworkDeploy'
  params: {
    hubNetwork:hubNetwork
  }
}




