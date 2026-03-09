targetScope = 'subscription'

param rgName string
param secondLocation string 
param secondVnetName string
param secondSubnet array
param secondvnetaddressprefixes array
param clusterDbVnetResourceId string
param aksAdminsGroupId string


// Create VNet with a single subnet for the AKS worker nodes
module nodesVirtualNetwork2 'br/public:avm/res/network/virtual-network:0.7.2' = {
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
        remoteVirtualNetworkResourceId: clusterDbVnetResourceId
        useRemoteGateways: false
      }
    ]
  }
}

module secondManagedCluster 'br/public:avm/res/container-service/managed-cluster:0.12.0' = {
  name: 'managedClusterDeployment2'
  scope: resourceGroup(rgName)
  params: {
    // Required parameters
    name: 'aksclusterregion2'
    skuName: 'Base'
    skuTier: 'Standard'
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      adminGroupObjectIDs: [
        aksAdminsGroupId
      ]
    }
    publicNetworkAccess: 'Enabled'
    networkDataplane: 'azure'
    networkPlugin: 'azure'
    enableOidcIssuerProfile: true
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    primaryAgentPoolProfiles: [
      {
        count: 1
        minCount: 1
        enableAutoScaling: true
        maxCount: 4
        osType: 'Linux'
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS2_v2'
        vnetSubnetResourceId: nodesVirtualNetwork2.outputs.subnetResourceIds[0]
      }
    ]
    webApplicationRoutingEnabled: true
    location: secondLocation
    managedIdentities: {
      systemAssigned: true
    }
  }
}

output rgSecondClusterName string = nodesVirtualNetwork2.outputs.resourceGroupName
output aksClusterVnetRegion2ResourceId string = nodesVirtualNetwork2.outputs.resourceId
output secondoidcIssuerUrl string = secondManagedCluster.outputs.?oidcIssuerUrl ?? ''
output secondAKSCluseterName string = secondManagedCluster.outputs.name
