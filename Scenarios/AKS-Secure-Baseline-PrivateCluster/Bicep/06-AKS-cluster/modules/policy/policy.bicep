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
