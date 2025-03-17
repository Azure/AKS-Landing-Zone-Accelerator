//az deployment sub create --location $LOCATION --template-file main.bicep --parameters @main.json --name aksLZAAllInOne --parameters aksadminaccessprincipalId=<your Azure entra group principal id>

// Target scope at subscription level
targetScope = 'subscription'


// Parameters
param mainRegion string = deployment().location 
param secondaryRegion string
param sharedResourcesRegion string 
param aksadminaccessprincipalId string
param isSecondaryRegionDeployment bool = false
param isMultiRegionDeployment bool = true
param aksClusterName string = isSecondaryRegionDeployment ? 'aksSecondaryRegion' :'aksMainRegion'
//param cosmosDbAccountName string



// Resource Group for Spokes
param multiRegionSharedRgName string = 'AKS-LZA-SHARED-${toUpper(mainRegion)}'


// Create Resource Group for shared resources
resource sharedRg 'Microsoft.Resources/resourceGroups@2022-09-01' = if(!isSecondaryRegionDeployment) {
  name: multiRegionSharedRgName
  location: sharedResourcesRegion
}


// Create Azure Front Door by calling the front door module
module frontDoorModule './FrontDoor/frontDoor.bicep' = if (!isSecondaryRegionDeployment) {
  dependsOn:[aksModuleMainRegion]
  name: 'AKSLZAFrontDoor'
  scope: sharedRg
  params: {
    location: mainRegion
  }
}

module acsReplicaModule './Container-Registry/containerRegistryReplica.bicep' = if (!isSecondaryRegionDeployment) {
  name: 'AcrReplica'
  scope: sharedRg
  params: {
    containerRegistryName: aksModuleMainRegion.outputs.acrName
    acrReplicaName: 'aksLzaContainerRegistryReplica'
    secondaryRegion: secondaryRegion
  }
}

//Create an additional cluster in a different region
module aksModuleMainRegion './AksCLuster/aksCluster.bicep' =  {
  name: aksClusterName
  scope: subscription() 
  params: {
    location: isSecondaryRegionDeployment ? secondaryRegion : mainRegion
    aksClusterName: aksClusterName
    aksadminaccessprincipalId:aksadminaccessprincipalId
    isMultiRegionDeployment: isMultiRegionDeployment
    multiRegionSharedRgName : multiRegionSharedRgName
    isSecondaryRegionDeployment: isSecondaryRegionDeployment
  }
}

module roleAssignmentModule './Role-Assignment/role-assignments.bicep' =  {
  name: 'roleAssignment'
  scope: resourceGroup(multiRegionSharedRgName)
  dependsOn: [frontDoorModule, acsReplicaModule]
  params: {
    acrName:aksModuleMainRegion.outputs.acrName
    aksClusterName:aksModuleMainRegion.outputs.aksClusterName
    keyVaultName: aksModuleMainRegion.outputs.keyVaultName
    multiRegionSharedRgName: multiRegionSharedRgName
    spokeResourceGroupName: aksModuleMainRegion.outputs.rgSpokeName
    vmSystemAssignedMIPrincipalId: aksModuleMainRegion.outputs.vmSystemAssignedMIPrincipalId
  }
}

// //Create an additional cluster in a different region
// module aksModuleSecondaryRegion './AksCLuster/aksCluster.bicep' = if (isSecondaryRegion) {
//   name: 'createAksSecondaryRegion'
//   scope: subscription() 
//   params: {
//     location: secondaryRegion
//     aksClusterName: 'aksSecondaryRegion'
//     aksadminaccessprincipalId:aksadminaccessprincipalId
//     acrRgName:rgSharedName
//   }
// }

// resource spokeRg 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {  
//   dependsOn: [aksModuleMainRegion]
//   scope: subscription()
//   name: rgSpokeNameMainRegion
// }

// resource spokeRg2 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {  
//   dependsOn: [aksModuleSecondaryRegion]
//   scope: subscription()
//   name: rgSpokeNameSecondaryRegion
// }


// module cosmosDbModuleMain './CosmosDB/cosmosDb2.bicep' = {
//   dependsOn: [aksModuleMainRegion]
//   name: 'createCosmosDbMainRegion'
//   scope: spokeRg
//   params: {
//     primaryRegion:''
//     secondaryRegion:''
//   }
// }

// module cosmosDbModuleSecondary './CosmosDB/cosmosDb2.bicep' = {
//   dependsOn: [aksModuleSecondaryRegion]
//   scope: spokeRg2
//   name: 'createCosmosDbSecondaryRegion'
//   params: {
//     primaryRegion:''
//     secondaryRegion:''
//   }
// }


