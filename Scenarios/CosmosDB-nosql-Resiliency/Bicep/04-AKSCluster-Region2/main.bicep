targetScope = 'subscription'

@description('The name of the resource group for the second region AKS cluster.')
param rgName string

@description('The Azure region for the second AKS cluster.')
param secondLocation string

@description('The name of the virtual network in the second region.')
param secondVnetName string

@description('The subnet definitions for the second region VNet.')
param secondSubnet array

@description('The address prefixes for the second region VNet.')
param secondvnetaddressprefixes array

@description('The resource ID of the database VNet for cross-region peering.')
param clusterDbVnetResourceId string

@description('The object ID of the Entra ID group for AKS cluster admins.')
param aksAdminsGroupId string

@description('Optional. The AKS cluster SKU name. Set to "Automatic" for AKS Automatic mode, or "Base" for standard mode.')
@allowed([
  'Base'
  'Automatic'
])
param aksSkuName string = 'Base'

var isAutomatic = aksSkuName == 'Automatic'


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

// ===================== //
// AKS Cluster           //
// ===================== //
module secondManagedCluster 'br/public:avm/res/container-service/managed-cluster:0.12.0' = {
  name: 'managedClusterDeployment2'
  scope: resourceGroup(rgName)
  params: {
    name: 'aksclusterregion2'
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
        vnetSubnetResourceId: isAutomatic ? null : nodesVirtualNetwork2.outputs.subnetResourceIds[0]
      }
    ]
    webApplicationRoutingEnabled: true
    enableKeyvaultSecretsProvider: isAutomatic
    enableSecretRotation: isAutomatic
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
