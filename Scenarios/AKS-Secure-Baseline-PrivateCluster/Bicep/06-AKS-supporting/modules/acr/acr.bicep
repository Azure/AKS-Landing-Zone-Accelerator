param acrName string
param acrSkuName string

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: resourceGroup().location
  sku: {
    name: acrSkuName
  }
  properties: {
    adminUserEnabled: true
  }
}

output acrid string = acr.id
