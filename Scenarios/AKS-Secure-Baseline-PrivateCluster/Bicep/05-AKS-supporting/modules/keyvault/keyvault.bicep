param name string
param keyVaultsku string
param tenantId string

resource keyvault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  name: name
  location: resourceGroup().location
  properties: {
    sku: {
      family: 'A'
      name: keyVaultsku
    }
    accessPolicies: []
    tenantId: tenantId
    enabledForDiskEncryption: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

output keyvaultId string = keyvault.id
