
targetScope = 'subscription'

param isSecondaryRegion bool = false
param rgSharedName string
param acrRegistryName string

var tagName = 'acrResourceExistsTag'


// Create Resource Group for shared resources
resource sharedRg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = if(!isSecondaryRegion) {
  name: rgSharedName
}

resource tags 'Microsoft.Resources/tags@2021-04-01' = if (!isSecondaryRegion) {
  name: 'default'
  properties: {
    tags: {
      acrResourceExistsTag: acrRegistryName
    }
  }
}

resource registryExisting 'Microsoft.ContainerRegistry/registries@2021-07-01' existing = if (isSecondaryRegion) {
  name: acrRegistryName
}


var acrRegistryNameOut = sharedRg.tags[?tagName] ?? acrRegistryName
output acrRegistryNameOut string = isSecondaryRegion ? acrRegistryNameOut : acrRegistryName
