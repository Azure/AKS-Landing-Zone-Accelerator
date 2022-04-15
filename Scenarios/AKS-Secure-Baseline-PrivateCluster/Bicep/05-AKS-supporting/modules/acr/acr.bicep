param acrName string
param acrSkuName string
param location string = resourceGroup().location

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: acrSkuName
  }
  properties: {
    adminUserEnabled: true
  }
}

output acrid string = acr.id
