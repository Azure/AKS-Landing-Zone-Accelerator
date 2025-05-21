// Target scope at subscription level
targetScope = 'subscription'


// Parameters
param aksadminaccessprincipalId string
param isSecondaryRegionDeployment bool = false
param isMultiRegionDeployment bool = true
param aksClusterName string = isSecondaryRegionDeployment ? 'aksLZASecondaryRegion' :'aksLZAMainRegion'

// Resource Group for Spokes
param multiRegionSharedRgName string = 'AKS-LZA-SHARED-RG'


// Create Resource Group for shared resources
resource sharedRg 'Microsoft.Resources/resourceGroups@2022-09-01' = if(!isSecondaryRegionDeployment) {
  name: multiRegionSharedRgName
  location: deployment().location
}


// Create Azure Front Door by calling the front door module
module frontDoorModule './FrontDoor/frontDoor.bicep' = if (!isSecondaryRegionDeployment) {
  dependsOn:[aksClusterModule]
  name: 'AKSLZAFrontDoor'
  scope: sharedRg
  params: {
    location: deployment().location
  }
}



//Create an additional cluster in a different region
module aksClusterModule './AksCLuster/aksCluster.bicep' =  {
  name: aksClusterName
  scope: subscription() 
  params: {
    location: deployment().location
    aksClusterName: aksClusterName
    isMultiRegionDeployment: isMultiRegionDeployment
    isSecondaryRegionDeployment: isSecondaryRegionDeployment
    multiRegionSharedRgName: multiRegionSharedRgName
  }
}

module roleAssignmentModule './Role-Assignment/role-assignments.bicep' =  {
  name: 'roleAssignment'
  scope: resourceGroup(multiRegionSharedRgName)
  dependsOn: [frontDoorModule]
  params: {
    acrName:aksClusterModule.outputs.acrName
    aksClusterName:aksClusterModule.outputs.aksClusterName
    keyVaultName: aksClusterModule.outputs.keyVaultName
    multiRegionSharedRgName: multiRegionSharedRgName
    spokeResourceGroupName: aksClusterModule.outputs.rgSpokeName
    vmSystemAssignedMIPrincipalId: aksClusterModule.outputs.vmSystemAssignedMIPrincipalId
  }
}
