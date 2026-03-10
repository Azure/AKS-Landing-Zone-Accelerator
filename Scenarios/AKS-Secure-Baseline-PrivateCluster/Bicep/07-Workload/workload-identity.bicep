targetScope = 'subscription'

@description('The name of the resource group containing the AKS cluster and Key Vault.')
param rgName string

@description('The location for the workload identity resources.')
param location string = deployment().location

@description('The name of the workload managed identity.')
param workloadIdentityName string = 'workload-identity'

@description('The OIDC issuer URL from the AKS cluster. Get this from the 06-AKS-cluster deployment output.')
param oidcIssuerUrl string

@description('The Kubernetes namespace where the workload will run.')
param workloadNamespace string = 'default'

@description('The Kubernetes service account name used by the workload.')
param workloadServiceAccountName string = 'workload-sa'

@description('The name of the Key Vault to grant access to.')
param keyvaultName string

// ===================== //
// Workload Identity     //
// ===================== //

// Create a user-assigned managed identity with a federated credential
// that trusts the AKS OIDC issuer for the specified K8s service account.
module workloadManagedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.5.0' = {
  scope: resourceGroup(rgName)
  name: 'workloadIdentityDeployment'
  params: {
    name: workloadIdentityName
    location: location
    federatedIdentityCredentials: [
      {
        name: '${workloadIdentityName}-federated-credential'
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: oidcIssuerUrl
        subject: 'system:serviceaccount:${workloadNamespace}:${workloadServiceAccountName}'
      }
    ]
  }
}

// Grant the workload identity "Key Vault Secrets User" role on the Key Vault
// This allows the CSI driver to read secrets at runtime without base64-encoded K8s Secrets.
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  scope: resourceGroup(rgName)
  name: keyvaultName
}

module kvWorkloadRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.2' = {
  scope: resourceGroup(rgName)
  name: 'kv-workload-identity-role'
  params: {
    principalId: workloadManagedIdentity.outputs.principalId
    resourceId: keyVault.id
    roleDefinitionId: '4633458b-17de-408a-b874-0445c86b69e6' // Key Vault Secrets User
    principalType: 'ServicePrincipal'
  }
}

// ===================== //
// Outputs               //
// ===================== //

@description('The client ID of the workload managed identity. Use this in the Kubernetes ServiceAccount annotation and SecretProviderClass.')
output workloadIdentityClientId string = workloadManagedIdentity.outputs.clientId

@description('The principal ID (object ID) of the workload managed identity.')
output workloadIdentityPrincipalId string = workloadManagedIdentity.outputs.principalId

@description('The resource ID of the workload managed identity.')
output workloadIdentityResourceId string = workloadManagedIdentity.outputs.resourceId

@description('The name of the workload managed identity.')
output workloadIdentityName string = workloadManagedIdentity.outputs.name
