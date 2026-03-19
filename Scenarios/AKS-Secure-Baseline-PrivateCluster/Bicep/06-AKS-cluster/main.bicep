targetScope = 'subscription'

@description('The name of the resource group for the AKS cluster.')
param rgName string

@description('The name of the spoke virtual network.')
param vnetName string

@description('The name of the AKS subnet.')
param subnetName string

@description('The name of the user-assigned managed identity for AKS.')
param aksIdentityName string

@description('The Azure region for all resources.')
param location string = deployment().location

@description('Enable cluster autoscaling.')
param enableAutoScaling bool

@description('Cluster autoscaler profile settings.')
param autoScalingProfile object

@description('The object ID of the Entra ID group for AKS cluster admins.')
param aksAdminAccessPrincipalId string

@description('The Kubernetes version for the AKS cluster.')
param kubernetesVersion string

@description('The name of the Key Vault deployed in 05-AKS-supporting.')
param keyVaultName string

@description('The name of the Container Registry deployed in 05-AKS-supporting.')
param acrName string

@description('The name of the AKS cluster.')
param aksClusterName string

@description('Enable AKS private cluster with private DNS zone.')
param enablePrivateCluster bool = true

@description('The VM size for AKS node pools.')
param vmSize string = 'Standard_D4d_v5'

@description('The network plugin for the AKS cluster.')
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

@description('Availability zones for AKS node pools. Defaults to auto-detected zones via pickZones(). Set to empty array [] to disable.')
param availabilityZones array = pickZones('Microsoft.ContainerService', 'managedClusters', location, 3)

@description('Enable etcd encryption with KMS v2. Requires a Key Vault key named "aks-etcd-kms".')
param enableKmsEncryption bool = true

@description('The Key Vault key URI for KMS v2 encryption (e.g., https://myvault.vault.azure.net/keys/aks-etcd-kms). Required when enableKmsEncryption is true.')
param kmsKeyUri string = ''

var privateDnsZoneAksSuffixes = {
  AzureCloud: '.azmk8s.io'
  AzureUSGovernment: '.cx.aks.containerservice.azure.us'
  AzureChinaCloud: '.cx.prod.service.azk8s.cn'
  AzureGermanCloud: '' //TODO: what is the correct value here?
}

var privateDnsZoneAksName = 'privatelink.${toLower(location)}${privateDnsZoneAksSuffixes[environment().name]}'

// Standard mode uses user-assigned identity; Automatic mode uses system-assigned
var isAutomatic = aksSkuName == 'Automatic'

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  scope: resourceGroup(rgName)
  name: aksIdentityName
}

resource pvtDnsAksZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = if (enablePrivateCluster) {
  name: privateDnsZoneAksName
  scope: resourceGroup(rg.name)
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${subnetName}'
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  scope: resourceGroup(rg.name)
  name: keyVaultName
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
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
  name: 'log-aks'
  params: {
    name: 'log-aks'
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
        availabilityZones: availabilityZones
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
          'balance-similar-node-groups': autoScalingProfile.balanceSimilarNodeGroups ? 'true' : 'false'
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
          'skip-nodes-with-local-storage': autoScalingProfile.skipNodesWithLocalStorage ? 'true' : 'false'
          'skip-nodes-with-system-pods': autoScalingProfile.skipNodesWithSystemPods ? 'true' : 'false'
        }
      : null
    networkPlugin: networkPlugin == 'azure' ? 'azure' : 'kubenet'
    networkPluginMode: networkPlugin == 'azure' ? 'overlay' : null
    networkDataplane: networkPlugin == 'azure' ? 'cilium' : null
    outboundType: 'loadBalancer'
    dnsServiceIP: '192.168.100.10'
    serviceCidr: '192.168.100.0/24'
    podCidr: '172.17.0.0/16'
    apiServerAccessProfile: {
      enablePrivateCluster: enablePrivateCluster
      privateDNSZone: enablePrivateCluster ? pvtDnsAksZone.id : null
      enablePrivateClusterPublicFQDN: false
    }
    enableRBAC: true
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
      adminGroupObjectIDs: [
        aksAdminAccessPrincipalId
      ]
    }
    kubernetesVersion: kubernetesVersion
    enableOidcIssuerProfile: true
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
      azureKeyVaultKms: enableKmsEncryption && !empty(kmsKeyUri)
        ? {
            enabled: true
            keyId: kmsKeyUri
            keyVaultNetworkAccess: 'Private'
            keyVaultResourceId: keyVault.id
          }
        : null
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
          privateDNSZone: pvtDnsAksZone.id
          enablePrivateClusterPublicFQDN: false
        }
      : null
    aadProfile: {
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
      adminGroupObjectIDs: [
        aksAdminAccessPrincipalId
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
      azureKeyVaultKms: enableKmsEncryption && !empty(kmsKeyUri)
        ? {
            enabled: true
            keyId: kmsKeyUri
            keyVaultNetworkAccess: 'Private'
            keyVaultResourceId: keyVault.id
          }
        : null
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
    resourceId: acr.id
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}

// Grant AKS identity "Key Vault Crypto User" for KMS v2 etcd encryption
module kvCryptoAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = if (enableKmsEncryption) {
  scope: resourceGroup(rg.name)
  name: 'keyvault-aks-crypto'
  params: {
    principalId: isAutomatic
      ? (managedClusterAutomatic.?outputs.?kubeletIdentityObjectId ?? '')
      : aksIdentity.properties.principalId
    resourceId: keyVault.id
    roleDefinitionId: '12338af0-0e69-4776-bea7-57ae8d297424' // Key Vault Crypto User
    principalType: 'ServicePrincipal'
  }
}


