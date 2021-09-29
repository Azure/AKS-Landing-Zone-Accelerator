param principalId string
param roleGuid string
param applicationGatewayName string

resource applicationGateway 'Microsoft.Network/applicationGateways@2021-02-01' existing = {
  name: applicationGatewayName
}

resource role_assignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(subscription().id, principalId, roleGuid)
  properties: {
    principalId: principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleGuid)
  }
  scope: applicationGateway
}
