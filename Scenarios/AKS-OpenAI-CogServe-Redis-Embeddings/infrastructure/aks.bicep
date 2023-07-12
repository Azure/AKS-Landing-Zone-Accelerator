param nameseed string = 'embedhhdingsy'
param location string = resourceGroup().location
param api_key string
param signedinuser string

//---------Kubernetes Construction---------
module aksconst 'aks-construction/bicep/main.bicep' = {
  name: 'aksconstruction'
  params: {
    location: location
    resourceName: nameseed
    enable_aad: true
    enableAzureRBAC: true
    registries_sku: 'Standard'
    omsagent: true
    retentionInDays: 30
    agentCount: 2
    agentVMSize: 'Standard_D2ds_v4'
    osDiskType: 'Managed'
    AksPaidSkuForSLA: true
    networkPolicy: 'azure'
    networkPluginMode: 'Overlay'
    azurepolicy: 'audit'
    acrPushRolePrincipalId: signedinuser
    adminPrincipalId: signedinuser
    AksDisableLocalAccounts: true
    custom_vnet: true
    upgradeChannel: 'stable'
    workloadIdentity: true
    CreateNetworkSecurityGroups:true

    //Workload Identity requires OidcIssuer to be configured on AKS
    oidcIssuer: true
    //We'll also enable the CSI driver for Key Vault
    keyVaultAksCSI: true
  }
}
output aksOidcIssuerUrl string = aksconst.outputs.aksOidcIssuerUrl
output aksClusterName string = aksconst.outputs.aksClusterName

// deploy keyvault
module keyVault 'aks-construction/bicep/keyvault.bicep' = {
  name: 'kv${nameseed}'
  params: {
    resourceName: 'app${nameseed}'
    keyVaultPurgeProtection: false
    keyVaultSoftDelete: false
    location: location
    privateLinks: false
  }
}
output kvAppName string = keyVault.outputs.keyVaultName

resource embeddingapp 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-embeding'
  location: location
}

resource fedCreds 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  name: 'string'
  parent: embeddingapp
  properties: {
    audiences: aksconst.outputs.aksOidcFedIdentityProperties.audiences
    issuer: aksconst.outputs.aksOidcFedIdentityProperties.issuer
    subject: 'system:serviceaccount:default:serversa'
  }
}


output credsinfo string = fedCreds.properties.issuer 

output nodeResourceGroup string = aksconst.outputs.aksNodeResourceGroup
output idembedingappClientId string = embeddingapp.properties.clientId
output idembedingappId string = embeddingapp.id

module kvSuperappRbac 'kvRbac.bicep' = {
  name: 'embedingKvRbac'
  params: {
    appclientId: embeddingapp.properties.principalId
    kvName: keyVault.outputs.keyVaultName
    openaiSecret: api_key
  }
}
