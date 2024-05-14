targetScope = 'subscription'

param rgName string
param location string = deployment().location
param workloadIdentityName string


module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
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



