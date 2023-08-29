param name string
param location string = resourceGroup().location
param tags object = {}

param customSubDomainName string = name
param deployments array = []
param kind string = 'OpenAI'
param publicNetworkAccess string = 'Enabled'
param sku object = {
  name: 'S0'
}

resource OpenAI 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
  }
  sku: sku
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: OpenAI
  name: deployment.name
  properties: {
    model: deployment.model
  }
  sku: contains(deployment, 'sku') ? deployment.sku : {
    name: 'Standard'
    capacity: deployment.capacity
  }
}]

output OpenAIEndpoint string = OpenAI.properties.endpoint
output OpenAIId string = OpenAI.id
output OpenAIName string = OpenAI.name
