param spoke1Network object = {}
param hubNetwork object = {}

resource spoke1_hub_peer 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-06-01' = {
  name: '${spoke1Network.virtualNetwork.name}/to-${hubNetwork.virtualNetwork.name}'
  properties: {
    allowForwardedTraffic: false
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId('Microsoft.Network/virtualNetworks', hubNetwork.virtualNetwork.name)
    }
  }
}
