targetScope = 'resourceGroup'
resource aks 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: ''
  location: 'uksouth'
  properties: {
    dnsPrefix: ''
    agentPoolProfiles: [
      {
        name: 'agentpool'
        osDiskSizeGB: 32
        count: 1
        vmSize: 'Standard_B2MS'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        type: 'VirtualMachineScaleSets'
        mode: 'System'
        vnetSubnetID: ''
      }
    ]
    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      serviceCidr: '10.1.0.0/24'
      dnsServiceIP: '10.1.0.10'
      dockerBridgeCidr: '172.17.0.1/16'
      outboundType: 'userDefinedRouting'
    }
      
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    addonProfiles: {
      httpApplicationRouting: {
        enabled: true
      }
    }
    nodeResourceGroup: ''
  }
  identity: {
    type: 'SystemAssigned'
  }
}
