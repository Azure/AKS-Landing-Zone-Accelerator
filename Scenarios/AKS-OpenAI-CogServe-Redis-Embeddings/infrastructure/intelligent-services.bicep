
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


param OpenAIEngine string = 'gpt-35-turbo'
param OpenAIEngineVersion string = '0301'
param OpenAIEmbeddingsEngineDoc string = 'text-embedding-ada-002'
param OpenAIEmbeddingsEngineDocVersion string = '2'

param location string = resourceGroup().location
var BlobContainerName = 'documents'


var openAIName = '${ResourcePrefix}-${UniqueString}'

//---------Kubernetes Construction---------
module aksconst 'AKS-Construction/bicep/main.bicep' = {
  name: 'aksconstruction'
  params: {
    location: location
    resourceName: openAIName
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
  }
}

output kvAppName string = aksconst.outputs.keyVaultName
output aksOidcIssuerUrl string = aksconst.outputs.aksOidcIssuerUrl
output aksClusterName string = aksconst.outputs.aksClusterName

resource OpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    customSubDomainName: openAIName
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }

  resource OpenAIDeploymentGPT 'deployments' = {
    name: 'gpt-deployment'
    sku: {
      name: 'Standard'
      capacity: 120
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: OpenAIEngine
        version: OpenAIEngineVersion
      }
    }
  }

  resource OpenAIDeploymentEmbeddings 'deployments' = {

    name: OpenAIEmbeddingsEngineDoc
    sku: {
      name: 'Standard'
      capacity: 120
    }
    
    properties: {
      model: {
        format: 'OpenAI'
        name: OpenAIEmbeddingsEngineDoc
        version: OpenAIEmbeddingsEngineDocVersion
      }
    }
    
    dependsOn: [
      OpenAIDeploymentGPT
    ]
  }

}

resource FormRecognizer 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '${ResourcePrefix}-${UniqueString}-formrecog'
  location: location
  kind: 'FormRecognizer'
  sku: {
    name: 'S0'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource Translator 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '${ResourcePrefix}-${UniqueString}-translator'
  location: location
  kind: 'TextTranslation'
  sku: {
    name: 'S1'
  }
  properties: {
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource StorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${ResourcePrefix}${UniqueString}sa'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }


  resource BlobService 'blobServices' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: []
      }
    }
  
    resource BlobContainer 'containers' = {
      name: BlobContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }

  resource QueueService 'queueServices' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: []
      }
    }

    resource DocumentProcessingQueue 'queues' = {
      name: 'doc-processing'
      properties: {
        metadata: {}
      }
    }
    
    resource DocumentProcessingPoisonQueue 'queues' = {
      name: 'doc-processing-poison'
      properties: {
        metadata: {}
      }
    }
  }
  
}


output blobAccountName string = StorageAccount.name
output openAIAccountName string = OpenAI.name
output openAIURL string = OpenAI.properties.endpoint
output formRecognizerAccountName string = FormRecognizer.name 
output translatorAccountName string = Translator.name

