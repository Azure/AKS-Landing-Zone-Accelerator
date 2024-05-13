targetScope = 'subscription'

param rgname string
param acrname string = 'eslzacr${uniqueString('acrvws', utcNow('u'))}'
param location string = deployment().location

// Resource group to hold all AKS supporting services
module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgname
  params: {
    name: rgname
    location: location
  }
}

// Create an Azure Container Registry
module registry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: acrname
  params: {
    name: acrname
    location: location
    acrAdminUserEnabled: true
    publicNetworkAccess: 'Enabled'
    exportPolicyStatus: 'enabled'
    acrSku: 'Premium'
  }
}

output acrResourceId string = registry.outputs.resourceId
output acrUrl string = registry.outputs.loginServer
output acrName string = acrname
