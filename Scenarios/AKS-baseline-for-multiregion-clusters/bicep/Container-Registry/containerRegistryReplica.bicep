// Parameters
param containerRegistryName string
param secondaryRegion string
param acrReplicaName string = 'acrreplica${resourceGroup().location}${uniqueString(uniqueString(subscription().id, utcNow()))}'
param acrReplicaNameSecondary string = 'acrreplica${secondaryRegion}${uniqueString(uniqueString(subscription().id, utcNow()))}'



//Existing Global container registry
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-01-01-preview'  existing = {
  name: containerRegistryName
}

//Container Registry Replication
resource registryReplica 'Microsoft.ContainerRegistry/registries/replications@2024-11-01-preview' = {
  parent: containerRegistry
  location: resourceGroup().location
  name: acrReplicaName
  properties: {
    regionEndpointEnabled: true
    zoneRedundancy: 'Disabled'
  }
}

//Container Registry Replication
resource secondaryReplica 'Microsoft.ContainerRegistry/registries/replications@2024-11-01-preview' = {
  parent: containerRegistry
  location: secondaryRegion
  name: acrReplicaNameSecondary
  properties: {
    regionEndpointEnabled: true
    zoneRedundancy: 'Disabled'
  }
}
