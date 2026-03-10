targetScope = 'resourceGroup'

resource ESAKSAssignment 'Microsoft.Authorization/policyAssignments@2025-11-01' = {
  name: 'EnterpriseScale AKS'
  location: resourceGroup().location
  properties: {
      policyDefinitionId: '/subscriptions/<SubscriptionId>/providers/Microsoft.Authorization/policySetDefinitions/EnterpriseScale-AKS-Initiative'
  }
  identity: {
    type: 'SystemAssigned'
  }
}
