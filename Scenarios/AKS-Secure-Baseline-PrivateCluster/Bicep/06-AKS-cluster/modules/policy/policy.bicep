resource DefAKSAssignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
    name: 'EnableDefenderForAKS'
    location: resourceGroup().location
    properties: {
        policyDefinitionId: '/providers/Microsoft.Authorization/policyDefinitions/64def556-fbad-4622-930e-72d1d5589bf5'
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
