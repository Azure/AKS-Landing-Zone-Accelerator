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

var privateDNSZoneAKSSuffixes = {
  AzureCloud: '.azmk8s.io'
  AzureUSGovernment: '.cx.aks.containerservice.azure.us'
  AzureChinaCloud: '.cx.prod.service.azk8s.cn'
  AzureGermanCloud: '' //TODO: what is the correct value here?
}

var privateDNSZoneAKSName = 'privatelink.${toLower(location)}${privateDNSZoneAKSSuffixes[environment().name]}'

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
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

module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
    roleAssignments: [
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

module workspace 'br/public:avm/res/operational-insights/workspace:0.9.0' = {
  scope: resourceGroup(rg.name)
  name: 'akslaworkspace'
  params: {
    name: 'akslaworkspace'
    location: location
  }
}

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.9.0' = {
  scope: resourceGroup(rg.name)
  name: aksClusterName
  params: {
    name: aksClusterName
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
    autoScalerProfileBalanceSimilarNodeGroups: enableAutoScaling ? autoScalingProfile.balanceSimilarNodeGroups : null
    autoScalerProfileExpander: enableAutoScaling ? autoScalingProfile.expander : null
    autoScalerProfileMaxEmptyBulkDelete: enableAutoScaling ? autoScalingProfile.maxEmptyBulkDelete : null
    autoScalerProfileMaxGracefulTerminationSec: enableAutoScaling ? autoScalingProfile.maxGracefulTerminationSec : null
    autoScalerProfileMaxNodeProvisionTime: enableAutoScaling ? autoScalingProfile.maxNodeProvisionTime : null
    autoScalerProfileMaxTotalUnreadyPercentage: enableAutoScaling ? autoScalingProfile.maxTotalUnreadyPercentage : null
    autoScalerProfileNewPodScaleUpDelay: enableAutoScaling ? autoScalingProfile.newPodScaleUpDelay : null
    autoScalerProfileOkTotalUnreadyCount: enableAutoScaling ? autoScalingProfile.okTotalUnreadyCount : null
    autoScalerProfileScaleDownDelayAfterAdd: enableAutoScaling ? autoScalingProfile.scaleDownDelayAfterAdd : null
    autoScalerProfileScaleDownDelayAfterDelete: enableAutoScaling ? autoScalingProfile.scaleDownDelayAfterDelete : null
    autoScalerProfileScaleDownDelayAfterFailure: enableAutoScaling
      ? autoScalingProfile.scaleDownDelayAfterFailure
      : null
    autoScalerProfileScaleDownUnneededTime: enableAutoScaling ? autoScalingProfile.scaleDownUnneededTime : null
    autoScalerProfileScaleDownUnreadyTime: enableAutoScaling ? autoScalingProfile.scaleDownUnreadyTime : null
    autoScalerProfileScanInterval: enableAutoScaling ? autoScalingProfile.scanInterval : null
    autoScalerProfileSkipNodesWithLocalStorage: enableAutoScaling ? autoScalingProfile.skipNodesWithLocalStorage : null
    autoScalerProfileSkipNodesWithSystemPods: enableAutoScaling ? autoScalingProfile.skipNodesWithSystemPods : null
    autoScalerProfileUtilizationThreshold: enableAutoScaling ? autoScalingProfile.scaleDownUtilizationThreshold : null
    networkPlugin: networkPlugin == 'azure' ? 'azure' : 'kubenet'
    outboundType: 'loadBalancer'
    dnsServiceIP: '192.168.100.10'
    serviceCidr: '192.168.100.0/24'
    networkPolicy: 'calico'
    podCidr: networkPlugin == 'kubenet' ? '172.17.0.0/16' : null
    enablePrivateCluster: enablePrivateCluster
    privateDNSZone: enablePrivateCluster ? pvtdnsAKSZone.id : null
    enablePrivateClusterPublicFQDN: false
    enableRBAC: true
    aadProfile:{
       aadProfileEnableAzureRBAC: true
    aadProfileManaged: true
    aadProfileTenantId: subscription().tenantId
    aadProfileAdminGroupObjectIDs: [
     aksadminaccessprincipalId
    ]

    }
    
    kubernetesVersion: kubernetesVersion
   
    omsAgentEnabled: true
    monitoringWorkspaceResourceId: workspace.outputs.resourceId
    azurePolicyEnabled: true
    webApplicationRoutingEnabled: true
    enableDnsZoneContributorRoleAssignment: true
    httpApplicationRoutingEnabled: false
    enableKeyvaultSecretsProvider: true
    managedIdentities: {
      userAssignedResourceIds: [
        aksIdentity.id
      ]
    }
  }
}

module kvAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: 'keyvault-aks-identity'
  params: {
    principalId: managedCluster.outputs.keyvaultIdentityClientId
    resourceId: keyVault.id
    roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
    principalType: 'ServicePrincipal'
  }
}

module acrAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: 'acr-aks-identity'
  params: {
    principalId: managedCluster.outputs.kubeletIdentityObjectId
    resourceId: ACR.id
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}


