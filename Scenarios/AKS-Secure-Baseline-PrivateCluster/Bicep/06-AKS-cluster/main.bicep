targetScope = 'subscription'

param rgName string
param vnetName string
param subnetName string
param aksIdentityName string
param location string = deployment().location
param enableAutoScaling bool
param autoScalingProfile object
param aksadminaccessprincipalId string
param kubernetesVersion string
@description('The name of the keyVault you deployed in the previous step (check Azure portal if you need to).')
param keyvaultName string
@description('The name of the Container registry you deployed in the previous step (check Azure portal if you need to).')
param acrName string
param aksClusterName string
param enablePrivateCluster bool = true
param vmSize string = 'Standard_D4d_v5'

@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string

@description('Optional. The AKS cluster SKU name. Set to "Automatic" for AKS Automatic mode, or "Base" for standard mode.')
@allowed([
  'Base'
  'Automatic'
])
param aksSkuName string = 'Base'

var privateDNSZoneAKSSuffixes = {
  AzureCloud: '.azmk8s.io'
  AzureUSGovernment: '.cx.aks.containerservice.azure.us'
  AzureChinaCloud: '.cx.prod.service.azk8s.cn'
  AzureGermanCloud: '' //TODO: what is the correct value here?
}

var privateDNSZoneAKSName = 'privatelink.${toLower(location)}${privateDNSZoneAKSSuffixes[environment().name]}'

// Standard mode uses user-assigned identity; Automatic mode uses system-assigned
var isAutomatic = aksSkuName == 'Automatic'

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  scope: resourceGroup(rgName)
  name: aksIdentityName
}

resource pvtdnsAKSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (enablePrivateCluster) {
  name: privateDNSZoneAKSName
  scope: resourceGroup(rg.name)
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${subnetName}'
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  scope: resourceGroup(rg.name)
  name: keyvaultName
}

resource ACR 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  scope: resourceGroup(rg.name)
  name: acrName
}

module rg 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
    roleAssignments: isAutomatic
      ? []
      : [
          {
            principalId: aksIdentity.properties.principalId
            roleDefinitionIdOrName: 'f1a07417-d97a-45cb-824c-7a7467783830'
          }
          {
            principalId: aksIdentity.properties.principalId
            roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
          }
        ]
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.15.0' = {
  scope: resourceGroup(rg.name)
  name: 'akslaworkspace'
  params: {
    name: 'akslaworkspace'
    location: location
  }
}

// ===================== //
// Standard AKS Cluster  //
// ===================== //
module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.12.0' = if (!isAutomatic) {
  scope: resourceGroup(rg.name)
  name: aksClusterName
  params: {
    name: aksClusterName
    skuName: 'Base'
    skuTier: 'Standard'
    primaryAgentPoolProfiles: [
      {
        availabilityZones: [
          3
        ]
        count: 3
        enableAutoScaling: true
        maxCount: 3
        maxPods: 30
        minCount: 1
        mode: 'System'
        name: 'defaultpool'
        osDiskSizeGB: 30
        osType: 'Linux'
        type: 'VirtualMachineScaleSets'
        vmSize: vmSize
        vnetSubnetResourceId: aksSubnet.id
      }
    ]
    autoScalerProfile: enableAutoScaling
      ? {
          'balance-similar-node-groups': '${autoScalingProfile.balanceSimilarNodeGroups}'
          expander: autoScalingProfile.expander
          'max-empty-bulk-delete': '${autoScalingProfile.maxEmptyBulkDelete}'
          'max-graceful-termination-sec': '${autoScalingProfile.maxGracefulTerminationSec}'
          'max-node-provision-time': autoScalingProfile.maxNodeProvisionTime
          'max-total-unready-percentage': '${autoScalingProfile.maxTotalUnreadyPercentage}'
          'new-pod-scale-up-delay': autoScalingProfile.newPodScaleUpDelay
          'ok-total-unready-count': '${autoScalingProfile.okTotalUnreadyCount}'
          'scale-down-delay-after-add': autoScalingProfile.scaleDownDelayAfterAdd
          'scale-down-delay-after-delete': autoScalingProfile.scaleDownDelayAfterDelete
          'scale-down-delay-after-failure': autoScalingProfile.scaleDownDelayAfterFailure
          'scale-down-unneeded-time': autoScalingProfile.scaleDownUnneededTime
          'scale-down-unready-time': autoScalingProfile.scaleDownUnreadyTime
          'scale-down-utilization-threshold': autoScalingProfile.scaleDownUtilizationThreshold
          'scan-interval': autoScalingProfile.scanInterval
          'skip-nodes-with-local-storage': '${autoScalingProfile.skipNodesWithLocalStorage}'
          'skip-nodes-with-system-pods': '${autoScalingProfile.skipNodesWithSystemPods}'
        }
      : null
    networkPlugin: networkPlugin == 'azure' ? 'azure' : 'kubenet'
    outboundType: 'loadBalancer'
    dnsServiceIP: '192.168.100.10'
    serviceCidr: '192.168.100.0/24'
    networkPolicy: 'calico'
    podCidr: networkPlugin == 'kubenet' ? '172.17.0.0/16' : null
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
      privateDNSZone: enablePrivateCluster ? pvtdnsAKSZone.id : null
      enablePrivateClusterPublicFQDN: false
    }
    enableRBAC: true
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
      adminGroupObjectIDs: [
        aksadminaccessprincipalId
      ]
    }
    kubernetesVersion: kubernetesVersion
    enableOidcIssuerProfile: true
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    omsAgentEnabled: true
    monitoringWorkspaceResourceId: workspace.outputs.resourceId
    azurePolicyEnabled: true
    webApplicationRoutingEnabled: true
    enableDnsZoneContributorRoleAssignment: true
    httpApplicationRoutingEnabled: false
    enableKeyvaultSecretsProvider: true
    enableSecretRotation: true
    managedIdentities: {
      userAssignedResourceIds: [
        aksIdentity.id
      ]
    }
  }
}

// ===================== //
// AKS Automatic Cluster //
// ===================== //
module managedClusterAutomatic 'br/public:avm/res/container-service/managed-cluster:0.12.0' = if (isAutomatic) {
  scope: resourceGroup(rg.name)
  name: '${aksClusterName}-auto'
  params: {
    name: aksClusterName
    skuName: 'Automatic'
    skuTier: 'Standard'
    primaryAgentPoolProfiles: [
      {
        name: 'systempool'
        count: 3
        vmSize: vmSize
        mode: 'System'
      }
    ]
    nodeProvisioningProfile: {
      mode: 'Auto'
    }
    nodeResourceGroupProfile: {
      restrictionLevel: 'ReadOnly'
    }
    outboundType: 'managedNATGateway'
    publicNetworkAccess: enablePrivateCluster ? 'Disabled' : 'Enabled'
    apiServerAccessProfile: enablePrivateCluster
      ? {
          enablePrivateCluster: true
          privateDNSZone: pvtdnsAKSZone.id
          enablePrivateClusterPublicFQDN: false
        }
      : null
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
      adminGroupObjectIDs: [
        aksadminaccessprincipalId
      ]
    }
    disableLocalAccounts: true
    enableRBAC: true
    kubernetesVersion: kubernetesVersion
    enableOidcIssuerProfile: true
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    autoUpgradeProfile: {
      nodeOSUpgradeChannel: 'NodeImage'
      upgradeChannel: 'stable'
    }
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
      verticalPodAutoscaler: {
        enabled: true
      }
    }
    omsAgentEnabled: true
    monitoringWorkspaceResourceId: workspace.outputs.resourceId
    azurePolicyEnabled: true
    webApplicationRoutingEnabled: true
    enableDnsZoneContributorRoleAssignment: true
    enableKeyvaultSecretsProvider: true
    enableSecretRotation: true
    managedIdentities: {
      systemAssigned: true
    }
  }
}

module kvAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  scope: resourceGroup(rg.name)
  name: 'keyvault-aks-identity'
  params: {
    principalId: isAutomatic
      ? (managedClusterAutomatic.?outputs.?keyvaultIdentityClientId ?? '')
      : (managedCluster.?outputs.?keyvaultIdentityClientId ?? '')
    resourceId: keyVault.id
    roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
    principalType: 'ServicePrincipal'
  }
}

module acrAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  scope: resourceGroup(rg.name)
  name: 'acr-aks-identity'
  params: {
    principalId: isAutomatic
      ? (managedClusterAutomatic.?outputs.?kubeletIdentityObjectId ?? '')
      : (managedCluster.?outputs.?kubeletIdentityObjectId ?? '')
    resourceId: ACR.id
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}


