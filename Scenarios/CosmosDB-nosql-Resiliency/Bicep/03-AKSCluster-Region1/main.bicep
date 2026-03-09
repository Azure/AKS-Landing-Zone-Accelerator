targetScope = 'subscription'

param rgName string
param location string = deployment().location
param aksAdminsGroupId string
param AKSvnetSubnetID string

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.12.0' = {
  name: 'managedClusterDeployment1'
  scope: resourceGroup(rgName)
  params: {
    // Required parameters
    name: 'aksclusterregion1'
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
        enableAutoScaling: true
        minCount: 1
        maxCount: 4
        osType: 'Linux'
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS2_v2'
        vnetSubnetResourceId: AKSvnetSubnetID
      }
    ]
    webApplicationRoutingEnabled: true
    omsAgentEnabled: true
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}

output firstoidcIssuerUrl string = managedCluster.outputs.?oidcIssuerUrl ?? ''
output firstAKSCluseterName string = managedCluster.outputs.name
