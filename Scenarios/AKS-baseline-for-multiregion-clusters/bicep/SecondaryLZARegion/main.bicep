
// Target scope at subscription level
targetScope = 'subscription'


// Parameters
param aksadminaccessprincipalId string
param isSecondaryRegionDeployment bool = true
param isMultiRegionDeployment bool = true
param aksClusterName string = isSecondaryRegionDeployment ? 'aksLZASecondaryRegion' :'aksLZAMainRegion'
param primaryACRName string

// Resource Group for Spokes
param multiRegionSharedRgName string = 'AKS-LZA-SHARED-RG'


// Create Resource Group for shared resources
resource sharedRg 'Microsoft.Resources/resourceGroups@2022-09-01'  existing = {
  name: multiRegionSharedRgName
}


module acsReplicaModule '../Container-Registry/containerRegistryReplica.bicep' = {
  name: 'AcrReplica'
  scope: sharedRg
  params: {
    containerRegistryName: primaryACRName
    secondaryRegion: deployment().location
  }
}

//Create an additional cluster in a different region
module aksClusterModule '../AksCLuster/aksCluster.bicep' =  {
  name: aksClusterName
  scope: subscription() 
  params: {
    location: deployment().location
    aksClusterName: aksClusterName
    aksadminaccessprincipalId:aksadminaccessprincipalId
    isMultiRegionDeployment: isMultiRegionDeployment
    isSecondaryRegionDeployment: isSecondaryRegionDeployment
    multiRegionSharedRgName: multiRegionSharedRgName
    primaryACRName: primaryACRName
  }
}

module roleAssignmentModule '../Role-Assignment/role-assignments.bicep' =  {
  name: 'roleAssignment'
  scope: resourceGroup(multiRegionSharedRgName)
  dependsOn: [acsReplicaModule]
  params: {
    acrName:primaryACRName
    aksClusterName:aksClusterModule.outputs.aksClusterName
    keyVaultName: aksClusterModule.outputs.keyVaultName
    multiRegionSharedRgName: multiRegionSharedRgName
    spokeResourceGroupName: aksClusterModule.outputs.rgSpokeName
    vmSystemAssignedMIPrincipalId: aksClusterModule.outputs.vmSystemAssignedMIPrincipalId
  }
}

