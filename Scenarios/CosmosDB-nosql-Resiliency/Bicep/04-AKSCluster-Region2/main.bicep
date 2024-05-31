targetScope = 'subscription'

param rgName string
param secondLocation string 
param secondVnetName string
param secondSubnet array
param secondvnetaddressprefixes array
param clusterDbVnetResourceId string
param aksAdminsGroupId string


// Create VNet with a single subnet for the AKS worker nodes
module nodesVirtualNetwork2 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'virtualNetworkDeployment'
  scope: resourceGroup(rgName)
  params: {
    // Required parameters
    addressPrefixes: secondvnetaddressprefixes
    subnets: secondSubnet
    name: secondVnetName
    location: secondLocation
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'aksclusterRegion2-database'
        remoteVirtualNetworkId: clusterDbVnetResourceId
        useRemoteGateways: false
      }
    ]
  }
}

module secondManagedCluster 'br/public:avm/res/container-service/managed-cluster:0.1.7' = {
  name: 'managedClusterDeployment2'
  scope: resourceGroup(rgName)
  params: {
    // Required parameters
    name: 'aksclusterregion2'
    aadProfileAdminGroupObjectIDs: [
      aksAdminsGroupId
    ]
    publicNetworkAccess: 'Enabled'
    networkDataplane: 'azure'
    networkPlugin: 'azure'
    enableWorkloadIdentity: true
    enableOidcIssuerProfile: true
    primaryAgentPoolProfile: [
      {
        count: 1
        minCount: 1
        enableAutoScaling: true
        maxCount: 4
        osType: 'Linux'
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS2_v2' 
        vnetSubnetID: nodesVirtualNetwork2.outputs.subnetResourceIds[0]
        webApplicationRoutingEnabled: true
      }
    ]
    location: secondLocation
    managedIdentities: {
      systemAssigned: true
    }
  }
}

output rgSecondClusterName string = nodesVirtualNetwork2.outputs.resourceGroupName
output aksClusterVnetRegion2ResourceId string = nodesVirtualNetwork2.outputs.resourceId
output secondoidcIssuerUrl string = secondManagedCluster.outputs.oidcIssuerUrl
output secondAKSCluseterName string = secondManagedCluster.outputs.name
