param policyAssignmentName string = 'EnableDefenderForAKS'
param policyDefinitionID string = '/providers/Microsoft.Authorization/policyDefinitions/64def556-fbad-4622-930e-72d1d5589bf5'

resource assignment 'Microsoft.Authorization/policyAssignments@2021-06-01' = {
    name: policyAssignmentName
    location: resourceGroup().location
    properties: {
        policyDefinitionId: policyDefinitionID
    }
    identity: {
      type: 'SystemAssigned'
    }
}
