targetScope = 'subscription'

param rgname string
param location string = deployment().location
param workloadIdentity string

// Resource group to hold all database related resources
module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgname
  params: {
    name: rgname
    location: location
  }
}

module userAssignedWorkloadIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
  name: 'userAssignedIdentityDeployment'
  scope: resourceGroup(rg.name)
  params: {
    // Required parameters
    name: workloadIdentity
    // Non-required parameters
    location: location
  }
}

output workloadIdentityId string = userAssignedWorkloadIdentity.outputs.principalId
