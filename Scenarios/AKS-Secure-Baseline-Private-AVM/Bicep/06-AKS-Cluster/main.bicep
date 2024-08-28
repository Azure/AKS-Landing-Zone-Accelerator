targetScope = 'subscription'

param rgName string
param vnetName string
param subnetName string
param appGatewayName string
param aksIdentityName string
param location string = deployment().location
param enableAutoScaling bool
param autoScalingProfile object
param aksadminaccessprincipalId string
param kubernetesVersion string
param keyvaultName string = 'eslz-kv-${uniqueString('acrvws', utcNow('u'))}'
param acrName string = 'eslzacr${uniqueString('acrvws', utcNow('u'))}'


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

resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  scope: resourceGroup(rgName)
  name: aksIdentityName
}

resource pvtdnsAKSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDNSZoneAKSName
  scope: resourceGroup(rg.name)
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${subnetName}'
}

resource appGateway 'Microsoft.Network/applicationGateways@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: appGatewayName
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

module workspace 'br/public:avm/res/operational-insights/workspace:0.3.4' = {
  scope: resourceGroup(rg.name)
  name: 'akslaworkspace'
  params: {
    name: 'akslaworkspace'
    location: location
  }
}

module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.1.2' = {
  scope: resourceGroup(rg.name)
  name: 'aksCluster'
  params: {
    name: 'aksCluster'
    primaryAgentPoolProfile: [
      {
        availabilityZones: [
          '3'
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
        serviceCidr: ''
        type: 'VirtualMachineScaleSets'
        vmSize: 'Standard_D4d_v5'
        vnetSubnetID: aksSubnet.id
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
    enablePrivateCluster: true
    privateDNSZone: pvtdnsAKSZone.id
    enablePrivateClusterPublicFQDN: false
    enableRBAC: true
    aadProfileAdminGroupObjectIDs: [
      aksadminaccessprincipalId
    ]
    kubernetesVersion: kubernetesVersion
    aadProfileEnableAzureRBAC: true
    aadProfileManaged: true
    aadProfileTenantId: subscription().tenantId
    omsAgentEnabled: true
    monitoringWorkspaceId: workspace.outputs.resourceId
    azurePolicyEnabled: true
    webApplicationRoutingEnabled: true
    // dnsZoneResourceId: '/subscriptions/029e4694-af3a-4d10-a193-e1cead6586a9/resourceGroups/dns/providers/Microsoft.Network/dnszones/leachlabs6.co.uk'
    enableDnsZoneContributorRoleAssignment: true
    // ingressApplicationGatewayEnabled: true
    // appGatewayResourceId: appGateway.id
    enableKeyvaultSecretsProvider: true
    managedIdentities: {
      userAssignedResourcesIds: [
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
    //resourceId: '/subscriptions/029e4694-af3a-4d10-a193-e1cead6586a9/resourceGroups/AKS-LZA-SPOKE/providers/Microsoft.KeyVault/vaults/eslz-kv-ydxy57gvxwipy'
    resourceId: keyVault.id
    roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
    principalType: 'ServicePrincipal'
  }
}

module acrAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: 'acr-aks-identity'
  params: {
    principalId: managedCluster.outputs.kubeletidentityObjectId
    //resourceId: '/subscriptions/029e4694-af3a-4d10-a193-e1cead6586a9/resourceGroups/AKS-LZA-SPOKE/providers/Microsoft.ContainerRegistry/registries/eslzacrydxy57gvxwipy'
    resourceId: ACR.id
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}


