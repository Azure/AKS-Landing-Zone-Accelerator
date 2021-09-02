param spoke1Network object = {}
param hubNetwork object = {}

resource hub_spoke1_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${hubNetwork.virtualNetwork.name}/to-${spoke1Network.virtualNetwork.name}'
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', spoke1Network.virtualNetwork.name)
    }
  }
}
