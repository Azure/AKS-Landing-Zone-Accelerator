resource NwcontributorRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '4d97b98b-1d4f-4787-a291-c67834d212e7'
}
resource vnetRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, managedCluster_resource.id, NwcontributorRoleDefinition.id)
  scope: virtualNetwork_aks
  properties: {
    roleDefinitionId: NwcontributorRoleDefinition.id
    //principalId: aciConnectorManagedIdentity.properties.principalId
    principalId: managedCluster_resource.properties.addonProfiles.aciConnectorLinux.identity.objectId
    principalType: 'ServicePrincipal'
  }
}


resource acrPullRoleDefinition 'Microsoft.Authorization/roleDefinitions@2018-01-01-preview' existing = {
  scope: subscription()
  name: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
}
resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-10-01-preview' = {
  name: guid(resourceGroup().id, containerRegistry.id, acrPullRoleDefinition.id)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRoleDefinition.id
    principalId: managedCluster_resource.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}
