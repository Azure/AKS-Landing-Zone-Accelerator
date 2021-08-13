param akscluster object = {}
param vNet object = {}

targetScope = 'resourceGroup'
resource aks_resource 'Microsoft.ContainerService/managedClusters@2021-05-01' = {
  name: akscluster.name
  location: akscluster.location
  properties: {
    dnsPrefix: akscluster.name
    agentPoolProfiles: [ for item in akscluster.agentPoolProfiles: {
      
        name: item.name
        osDiskSizeGB: item.osDiskSizeGB
        count: item.nodeCount
        vmSize: item.vmSize
        osType: item.osType
        osSKU: item.osSKU
        type: item.type
        mode: item.mode
        vnetSubnetID: item.subnetId
      
    }]
    networkProfile: {
      loadBalancerSku: akscluster.networkProfile.loadBalancerSku
      networkPlugin: akscluster.networkProfile.networkPlugin
      serviceCidr: akscluster.networkProfile.serviceCidr
      dnsServiceIP: akscluster.networkProfile.dnsServiceIP
      dockerBridgeCidr: akscluster.networkProfile.dockerBridgeCidr
    }
    nodeResourceGroup: akscluster.nodeResourceGroup
  }
  identity: {
    type: akscluster.identity
  }
}
