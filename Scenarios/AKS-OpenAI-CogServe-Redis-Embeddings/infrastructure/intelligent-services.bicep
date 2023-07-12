param ResourcePrefix string
param OpenAIName string
param OpenAIEngine string
param OpenAIEmbeddingsEngineDoc string
param UniqueString string // need to specify this in your deployment command
var BlobContainerName = 'documents'


resource OpenAI 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: '${OpenAIName}'
  location: resourceGroup().location
  kind: 'OpenAI'
  sku: {
    name: 'S0'
  }
  properties: {
    customSubDomainName: '${OpenAIName}'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
    publicNetworkAccess: 'Enabled'
  }
}

resource OpenAIDeploymentGPT 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = {
  name: '${OpenAI.name}/gpt-deployment'
  dependsOn: [
    OpenAI
  ]
  properties: {
    model: {
      format: 'OpenAI'
      name: 'gpt-35-turbo'
      version: '0301'
    }
    scaleSettings: {
      scaleType: 'Standard'
    }
  }
}

resource OpenAIDeploymentEngine 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = {
  name: '${OpenAI.name}/${OpenAIEngine}'
  dependsOn: [
    OpenAIDeploymentEmbeddings
  ]
  properties: {
    model: {
      format: 'OpenAI'
      // name: '${OpenAIEngine}'
      name: 'text-davinci-002'
      version: '1'
    }
    scaleSettings: {
      scaleType: 'Standard'
    }
  }
}

resource OpenAIDeploymentEmbeddings 'Microsoft.CognitiveServices/accounts/deployments@2022-12-01' = {
  name: '${OpenAI.name}/${OpenAIEmbeddingsEngineDoc}'
  dependsOn: [
    OpenAIDeploymentGPT
  ]
  properties: {
    model: {
      format: 'OpenAI'
      name: '${OpenAIEmbeddingsEngineDoc}'
      version: '2'
    }
    scaleSettings: {
      scaleType: 'Standard'
    }
  }
}

resource FormRecognizer 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: '${ResourcePrefix}-${UniqueString}-formrecog'
  location: resourceGroup().location
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

resource Translator 'Microsoft.CognitiveServices/accounts@2022-12-01' = {
  name: '${ResourcePrefix}-${UniqueString}-translator'
  location: resourceGroup().location
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

resource StorageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: '${ResourcePrefix}${UniqueString}sa'
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
}

resource BlobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${StorageAccount.name}/default/${BlobContainerName}'
  dependsOn: [
    StorageAccount
  ]
  properties: {
    publicAccess: 'None'
  }
}

resource QueueService 'Microsoft.Storage/storageAccounts/queueServices@2022-09-01' = {
  name: '${StorageAccount.name}/default'
  dependsOn: [
    StorageAccount
  ]
  properties: {
    cors: {
      corsRules: []
    }
  }
}

resource DocumentProcessingQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = {
  name: '${QueueService.name}/doc-processing'
  properties: {
    metadata: {}
  }
}

resource DocumentProcessingPoisonQueue 'Microsoft.Storage/storageAccounts/queueServices/queues@2022-09-01' = {
  name: '${QueueService.name}/doc-processing-poison'
  dependsOn: [
    DocumentProcessingQueue
  ]
  properties: {
    metadata: {}
  }
}
