targetScope = 'subscription'

@description('Signed In User Id')
param signedinuser string

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param ResourcePrefix string = 'aksembed'

@minLength(3)
@maxLength(10)
@description('Used to name all resources')
param UniqueString string // need to specify this in your deployment command


@description('OpenAI Service Name if already exists')
param openAIName string = ''
param openAIRGName string = ''

param OpenAIEngine string = 'gpt-35-turbo'
param OpenAIEngineVersion string = '0301'
param OpenAIEmbeddingsEngineDoc string = 'text-embedding-ada-002'
param OpenAIEmbeddingsEngineDocVersion string = '2'
param OpenAIQuota int = 120

param resourceGroupName string = ''
param location string = deployment().location


resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
name: !empty(resourceGroupName) ? resourceGroupName : 'openai-embedding-rg-${UniqueString}' 
  location: location
}

//---------Kubernetes Construction---------
module aksconst 'AKS-Construction/bicep/main.bicep' = {
  name: 'aksconstruction'
  scope: resourceGroup
  params: {
    location: location
    resourceName: '${ResourcePrefix}-${UniqueString}'
    enable_aad: true
    enableAzureRBAC: true
    omsagent: true
    retentionInDays: 30
    agentCount: 2
    agentVMSize: 'Standard_D2ds_v4'
    osDiskType: 'Managed'
    AksPaidSkuForSLA: true
    networkPolicy: 'azure'
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
    keyVaultCreate: true
    keyVaultOfficerRolePrincipalId: signedinuser
    warIngressNginx: true
  }
}

output kvAppName string = aksconst.outputs.keyVaultName
output aksOidcIssuerUrl string = aksconst.outputs.aksOidcIssuerUrl
output aksClusterName string = aksconst.outputs.aksClusterName

//---------OpenAI Construction---------

resource openAIRG 'Microsoft.Resources/resourceGroups@2021-04-01' existing = if (!empty(openAIRGName)) {
  name: !empty(openAIRGName) ? openAIRGName : resourceGroup.name
}


resource OpenAIExisting 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = if (!empty(openAIName)) {
  name: openAIName
  scope: openAIRG
  
  resource OpenAIDeploymentGPTExisting 'deployments' existing = if (!empty(openAIName)){
    name: OpenAIEngine
  }
  resource OpenAIDeploymentEmbeddingsExisting 'deployments' existing = if (!empty(openAIName)){
    name: OpenAIEmbeddingsEngineDoc
  }
}

module OpenAI 'openai.bicep' = if (empty(openAIName)) {
  name: 'openai'
  scope: resourceGroup
  
  params: {
    name: '${ResourcePrefix}${UniqueString}'
    location: location
    customSubDomainName: '${ResourcePrefix}${UniqueString}'
    sku: {
      name: 'S0'
    }
    deployments: [
      {
        name: OpenAIEngine
        model: {
          format: 'OpenAI'
          name: 'gpt-35-turbo'
          version: OpenAIEngineVersion
        }
        sku: {
          name: 'Standard'
          capacity: OpenAIQuota
        }
      }
      {
        name: OpenAIEmbeddingsEngineDoc
        model: {
          format: 'OpenAI'
          name: 'text-embedding-ada-002'
          version: OpenAIEmbeddingsEngineDocVersion
        }
        capacity: OpenAIQuota
      }
    ]
  }
}

//---------Form Recognizer and Translator Construction---------

module intelligentServices 'intelligent-services.bicep' = {
  name: 'intelligent-services'
  scope: resourceGroup
  
  params: {
    location: location
    resourcePrefix: '${ResourcePrefix}${UniqueString}'
  }
}



//---------Outputs Construction---------
output blobAccountName string = intelligentServices.outputs.StorageAccountName
output openAIAccountName string = ((empty(openAIName)) ? OpenAI.outputs.OpenAIName : OpenAIExisting.name)
output openAIURL string = ((empty(openAIName)) ? OpenAI.outputs.OpenAIEndpoint: OpenAIExisting.properties.endpoint)
output openAIEngineName string = OpenAIEngine
output openAIEmbeddingEngine string = OpenAIEmbeddingsEngineDoc
output openAIRGName string = ((empty(openAIName)) ? resourceGroup.name : openAIRG.name)
output formRecognizerName string = intelligentServices.outputs.FormRecognizerName 
output formRecognizerEndpoint string = intelligentServices.outputs.FormRecognizerEndpoint
output translatorName string = intelligentServices.outputs.TranslatorName


