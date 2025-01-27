// Parameters
param location string = deployment().location
param resourceGroupName string
param frontDoorName string
param containerRegistryName string
param cosmosDbAccountName string
param sharedResourceGroupName string
//param sharedResourceLocation string

// Target scope at subscription level
targetScope = 'subscription'

// Create Resource Group
resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: resourceGroupName
  location: location
}
// Create Resource Group
resource sharedrg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: sharedResourceGroupName
  location: location
}

//Create an additional cluster in a different region
module aksModule './AksCLuster/aksCluster.bicep' = {
  name: 'createAks'
  scope: subscription() 
  params: {
    aksClusterName: 'aks2'
    aksadminaccessprincipalId:''
  }
}

// Create Azure Front Door by calling the front door module
module frontDoorModule './FrontDoor/frontDoor.bicep' = {
  dependsOn: [aksModule]
  name: 'createFrontDoor'
  scope: rg
  params: {
    frontDoorName: frontDoorName
    location: location
  }
}

// Create Container Registry by calling the container registry module
module containerRegistryModule './Container-Registry/containerRegistry.bicep' = {
  dependsOn: [aksModule]
  name: 'createContainerRegistry'
  scope: rg
  params: {
    location: location
    containerRegistryName :containerRegistryName
  }
}

module cosmosDbModule './CosmosDB/cosmosDb.bicep' = {
  dependsOn: [aksModule]
  name: 'createCosmosDb'
  scope: rg
  params: {
    location: location
    cosmosDbAccountName: cosmosDbAccountName
    subnetName:''
    virtualNetworkName:''
  }
}

