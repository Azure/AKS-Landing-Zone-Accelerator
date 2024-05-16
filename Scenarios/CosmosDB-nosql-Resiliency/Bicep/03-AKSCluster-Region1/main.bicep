targetScope = 'subscription'

param rgName string
param location string = deployment().location
param aksAdminsGroupId string
param AKSvnetSubnetID string

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
    networkDataplane: 'azure'
    networkPlugin: 'azure'
    enableWorkloadIdentity: true
    enableOidcIssuerProfile: true
    primaryAgentPoolProfile: [
      {
        count: 1
        enableAutoScaling: true
        minCount: 1
        maxCount: 4
        osType: 'Linux'
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS2_v2' 
        vnetSubnetID: AKSvnetSubnetID 
        webApplicationRoutingEnabled: true
        networkDataplanne: 'azure'
        networkPlugin: 'azure'
        networkPluginMode: 'overlay'
        omsAgentEnabled: true
      }
    ]
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}

output firstoidcIssuerUrl string = managedCluster.outputs.oidcIssuerUrl
output firstAKSCluseterName string = managedCluster.outputs.name
