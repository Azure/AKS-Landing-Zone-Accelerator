param multiRegionSharedRgName string
param keyVaultName string
param aksClusterName string
param acrName string
param spokeResourceGroupName string
param vmSystemAssignedMIPrincipalId string



resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  scope: resourceGroup(spokeResourceGroupName)
  name: keyVaultName
}

resource ACR 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  scope: resourceGroup(multiRegionSharedRgName)
  name: acrName
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-09-01' existing = {
  scope: resourceGroup(spokeResourceGroupName)
  name: aksClusterName
}

module kvAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  scope: resourceGroup(spokeResourceGroupName)
  name: 'keyvault-aks-identity'
  params: {
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    resourceId: keyVault.id
    roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
    principalType: 'ServicePrincipal'
  }
}

module acrAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  scope: resourceGroup(multiRegionSharedRgName)
  name: 'acr-aks-identity'
  params: {
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    resourceId: ACR.id
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}

module vmAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  scope: resourceGroup(spokeResourceGroupName)
  name: 'vm-aks-identity'
  params: {
    principalId: vmSystemAssignedMIPrincipalId
    resourceId: aksCluster.id
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}

module vmACRAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  scope: resourceGroup(multiRegionSharedRgName)
  name: 'vm-acr-aks-identity'
  params: {
    principalId: vmSystemAssignedMIPrincipalId
    resourceId: ACR.id
    roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    principalType: 'ServicePrincipal'
  }
}
