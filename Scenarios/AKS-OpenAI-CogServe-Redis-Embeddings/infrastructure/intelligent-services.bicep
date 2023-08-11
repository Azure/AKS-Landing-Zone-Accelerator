param ResourcePrefix string
param OpenAIEngine string
param OpenAIEngineVersion string
param OpenAIEmbeddingsEngineDoc string
param OpenAIEmbeddingsEngineDocVersion string
param UniqueString string // need to specify this in your deployment command
param location string = resourceGroup().location
var BlobContainerName = 'documents'


var OpenAIName = '${ResourcePrefix}-${UniqueString}'

resource OpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: OpenAIName
  location: location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    customSubDomainName: OpenAIName
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
      capacity: 20
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



