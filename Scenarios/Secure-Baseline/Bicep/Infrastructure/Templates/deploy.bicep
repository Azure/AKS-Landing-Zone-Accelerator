targetScope = 'subscription'
param hubrgnames array = []
param spoke1rgnames array = []
param location string = ''
param hubNetwork object = {}
param spoke1Network object = {}

module hubRG '../Hub/Modules/resourceGroup.bicep' = {
  name: 'hubRGDeploy'
  params: {
    hubrgnames: hubrgnames
    location: location
  }
}

module spoke1RG '../Spoke/Modules/resourceGroup.bicep' = {
  name: 'spoke1RGDeploy'
  params: {
    spoke1rgnames: spoke1rgnames
    location: location
  }
}

module hubVNet '../Hub/Modules/network.bicep' = {
  scope: resourceGroup(hubNetwork.virtualNetwork.rg)
  name: 'hubNetworkDeploy'
  params: {
    hubNetwork: hubNetwork
  }
  dependsOn: [
    hubRG
  ]
}

module spoke1VNet '../Spoke/Modules/network.bicep' = {
  scope: resourceGroup(spoke1Network.virtualNetwork.rg)
  name: 'spoke1NetworkDeploy'
  params: {
    spoke1Network: spoke1Network
  }
  dependsOn: [
    spoke1RG
  ]
}

module hubVNet_spoke1VNet_Peer '../Hub/Modules/networkPeering.bicep' = {
  scope: resourceGroup(hubNetwork.virtualNetwork.rg)
  name: 'hubNetworkToSpoke1NetworkPeering'
  params: {
    hubNetwork: hubNetwork
    spoke1Network: spoke1Network
  }
  dependsOn: [
    hubVNet
    spoke1VNet
  ]
}

module spoke1VNet_hubVNet_Peer '../Spoke/Modules/networkPeering.bicep' = {
  scope: resourceGroup(spoke1Network.virtualNetwork.rg)
  name: 'spoke1NetworkToHubNetworkPeering'
  params: {
    hubNetwork: hubNetwork
    spoke1Network: spoke1Network
  }
  dependsOn: [
    hubVNet_spoke1VNet_Peer
  ]
}
