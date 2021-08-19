targetScope = 'subscription'
param hubrgnames array = []
param location string = ''
param hubNetwork object = {}

/*module hubRG './resourceGroup.bicep' = {
  name: 'hubRGDeploy'
  params: {
    hubrgnames:hubrgnames
    location:location
  }
}*/

module hubVnet '../../../Modules/network.bicep' = {
  scope: resourceGroup(hubNetwork.virtualNetwork.rg)
  name: 'hubNetworkDeploy'

}


