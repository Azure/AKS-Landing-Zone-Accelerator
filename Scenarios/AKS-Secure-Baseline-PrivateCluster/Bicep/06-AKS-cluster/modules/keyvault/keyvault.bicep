param keyvaultManagedIdentityObjectId string
param vaultName string
param aksuseraccessprincipalId string

resource keyvaultaccesspolicy 'Microsoft.KeyVault/vaults/accessPolicies@2021-06-01-preview' = {
  name: '${vaultName}/add'
  properties: {
    accessPolicies: [
      {
        objectId: keyvaultManagedIdentityObjectId
        permissions: {
          secrets: [
            'get'
            'list'
          ]
        }
        tenantId: subscription().tenantId
      }
      {
        objectId: aksuseraccessprincipalId
        permissions: {
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
          keys: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}
