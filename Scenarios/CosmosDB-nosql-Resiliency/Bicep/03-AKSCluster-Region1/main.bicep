targetScope = 'subscription'

param rgName string
param location string = deployment().location
param aksAdminsGroupId string
param AKSvnetSubnetID string

@description('Optional. The AKS cluster SKU name. Set to "Automatic" for AKS Automatic mode, or "Base" for standard mode.')
@allowed([
  'Base'
  'Automatic'
])
param aksSkuName string = 'Base'

var isAutomatic = aksSkuName == 'Automatic'

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.12.0' = {
  name: 'managedClusterDeployment1'
  scope: resourceGroup(rgName)
  params: {
    name: 'aksclusterregion1'
    skuName: aksSkuName
    skuTier: 'Standard'
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      adminGroupObjectIDs: [
        aksAdminsGroupId
      ]
    }
    disableLocalAccounts: isAutomatic
    publicNetworkAccess: 'Enabled'
    networkDataplane: isAutomatic ? null : 'azure'
    networkPlugin: isAutomatic ? null : 'azure'
    enableOidcIssuerProfile: true
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    nodeProvisioningProfile: isAutomatic ? { mode: 'Auto' } : null
    nodeResourceGroupProfile: isAutomatic ? { restrictionLevel: 'ReadOnly' } : null
    outboundType: isAutomatic ? 'managedNATGateway' : 'loadBalancer'
    autoUpgradeProfile: isAutomatic
      ? {
          nodeOSUpgradeChannel: 'NodeImage'
          upgradeChannel: 'stable'
        }
      : { upgradeChannel: 'stable' }
    workloadAutoScalerProfile: isAutomatic
      ? {
          keda: { enabled: true }
          verticalPodAutoscaler: { enabled: true }
        }
      : null
    primaryAgentPoolProfiles: [
      {
        count: 1
        enableAutoScaling: !isAutomatic
        minCount: isAutomatic ? null : 1
        maxCount: isAutomatic ? null : 4
        osType: 'Linux'
        mode: 'System'
        name: 'systempool'
        vmSize: 'Standard_DS2_v2'
        vnetSubnetResourceId: isAutomatic ? null : AKSvnetSubnetID
      }
    ]
    webApplicationRoutingEnabled: true
    omsAgentEnabled: true
    enableKeyvaultSecretsProvider: isAutomatic
    enableSecretRotation: isAutomatic
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}

output firstoidcIssuerUrl string = managedCluster.outputs.?oidcIssuerUrl ?? ''
output firstAKSCluseterName string = managedCluster.outputs.name
