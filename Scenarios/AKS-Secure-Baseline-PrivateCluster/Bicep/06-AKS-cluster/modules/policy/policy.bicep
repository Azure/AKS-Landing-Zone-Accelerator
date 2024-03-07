param location string = resourceGroup().location
param policySetDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/64def556-fbad-4622-930e-72d1d5589bf5'

resource DefAKSAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = if (environment().name == 'AzureCloud') {
  name: 'EnableDefenderForAKS'
  location: location
  properties: {
    policyDefinitionId: policySetDefinitionId
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// resource ESAKSAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
//   name: 'EnterpriseScale AKS'
//   location: resourceGroup().location
//   properties: {
//       policyDefinitionId: '/subscriptions/82e70289-bf40-45f9-8476-eab93d2031f4/providers/Microsoft.Authorization/policySetDefinitions/EnterpriseScale-AKS-Initiative'
//   }
//   identity: {
//     type: 'SystemAssigned'
//   }
// }
