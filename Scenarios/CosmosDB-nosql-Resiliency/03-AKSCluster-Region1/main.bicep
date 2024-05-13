targetScope = 'subscription'

param rgname string
param location string = deployment().location
param vnetname string
param subnets array
param vnetaddressprefixes array
param cosmosDbVnetResourceId string
param aksAdminsGroupId string

// Create resource group for the AKS Cluster nodes and associated resources.
module rgNodes 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: '${rgname}-networking'
  params: {
    name: '${rgname}-networking'
    location: location
  }
}

// Create VNet with a single subnet for the AKS worker nodes
module nodesVirtualNetwork1 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'virtualNetworkDeployment'
  scope: resourceGroup(rgNodes.name)
  dependsOn: [rgNodes]
  params: {
    // Required parameters
    addressPrefixes: vnetaddressprefixes
    subnets: subnets
    name: vnetname
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: 'aksclusterRegion1-database'
        remoteVirtualNetworkId: cosmosDbVnetResourceId
        useRemoteGateways: false
      }
    ]
  }
}

// Create resource group for the AKS Cluster nodes and associated resources.
module rgCluster 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'AKSClusterRegion1'
  params: {
    name: 'AKSClusterRegion1'
    location: location
  }
}

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.1.7' = {
  name: 'managedClusterDeployment1'
  scope: resourceGroup(rgCluster.name)
  params: {
    // Required parameters
    name: 'aksclusterRegion1'
    aadProfileAdminGroupObjectIDs: [
      aksAdminsGroupId
    ]
    publicNetworkAccess: 'Enabled'
    enableWorkloadIdentity: true
    enableOidcIssuerProfile: true
    primaryAgentPoolProfile: [
      {
        count: 1
        osType: 'Linux'
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS2_v2' 
        vnetSubnetID: nodesVirtualNetwork1.outputs.subnetResourceIds[0]
        webApplicationRoutingEnabled: true
        nodeResourceGroup: rgNodes.name
      }
    ]
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}

output aksClusterVnetRegion1ResourceId string = nodesVirtualNetwork1.outputs.resourceId
