targetScope = 'subscription'

param rgName string
param acrname string 
param location string = deployment().location

// Create an Azure Container Registry
module registry 'br/public:avm/res/container-registry/registry:0.1.1' = {
  scope: resourceGroup(rgName)
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
