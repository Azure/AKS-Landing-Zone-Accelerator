param location string = resourceGroup().location


param resourcePrefix string = ''
var BlobContainerName = 'documents'


//---------FormRecognizer Construction---------
resource FormRecognizer 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '${resourcePrefix}-formrecog'
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
//---------Translator Construction---------
resource Translator 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: '${resourcePrefix}-translator'
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
//-----------------Storage Account Construction-----------------
resource StorageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: '${resourcePrefix}sa'
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


output TranslatorName string = Translator.name
output FormRecognizerName string = FormRecognizer.name
output FormRecognizerEndpoint string = FormRecognizer.properties.endpoint
output StorageAccountName string = StorageAccount.name

