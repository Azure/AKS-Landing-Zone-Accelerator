// Parameters
param location string
param containerRegistryName string

// Global Container Registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Premium' // Premium tier is required for geo-replication
  }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

// Output the container registry ID for reference
output containerRegistryId string = containerRegistry.id
