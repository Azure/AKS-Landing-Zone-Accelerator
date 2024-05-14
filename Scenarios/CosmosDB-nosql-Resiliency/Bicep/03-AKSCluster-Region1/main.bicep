targetScope = 'subscription'

param rgName string
param location string = deployment().location
param aksAdminsGroupId string
param AKSvnetSubnetID string

// Create resource group for the AKS Cluster nodes and associated resources.
module rgNodes 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: '${rgName}-networking'
  params: {
    name: '${rgName}-networking'
    location: location
  }
}

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.1.7' = {
  name: 'managedClusterDeployment1'
  scope: resourceGroup(rgName)
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
        vnetSubnetID: AKSvnetSubnetID 
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

output firstoidcIssuerUrl string = managedCluster.outputs.oidcIssuerUrl
