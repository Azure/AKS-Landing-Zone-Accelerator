targetScope = 'subscription'

@description('The name of the resource group containing the workload identity.')
param rgName string

@description('The Azure region for the workload identity resources.')
param location string = deployment().location

@description('The name of the workload managed identity.')
param workloadIdentityName string


module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.5.0' = {
  name: 'userAssignedIdentityDeployment'
  scope: resourceGroup(rgName)
  params: {
    // Required parameters
    name: workloadIdentityName
    // Non-required parameters
    location: location
  }
}

output workloadIdentityObjectId string = userAssignedIdentity.outputs.principalId
output workloadIdentityClientId string = userAssignedIdentity.outputs.clientId
output workloadIdentityName string = workloadIdentityName
output workloadIdentityresourceId string = userAssignedIdentity.outputs.resourceId



