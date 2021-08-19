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

module hubFirewall '../Modules/azFirewall.bicep' = if (hubNetwork.azureFirewall.deploy){
  scope: resourceGroup(hubNetwork.azureFirewall.rg)
  name: 'hubFirewallDeploy'
  params: {
    hubNetwork:hubNetwork
  }
  dependsOn: [
    hubVNet
  ]
}


