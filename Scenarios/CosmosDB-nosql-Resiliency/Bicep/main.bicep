targetScope = 'subscription'

@description('UTC timestamp used for generating unique deployment names.')
param timestamp string = utcNow()

@description('A unique string derived from subscription, resource group, and timestamp.')
param UniqueString string = uniqueString(subscription().subscriptionId, resourceGroupName, timestamp)

@description('The name of the resource group for all resources.')
param resourceGroupName string = 'SimpleEcomRG'

@description('The Azure region for all resources.')
param location string = deployment().location


/// Deployment for the cosmosdb and its virtual network (01-Database/main.bicep)
@description('The name of the Cosmos DB account.')
param cosmosdbname string = 'cosmosdb${UniqueString}'

@description('The subnet definitions for the virtual network.')
param subnets array

@description('The address prefixes for the virtual network.')
param vnetaddressprefixes array

@description('The name of the virtual network.')
param vnetname string

  // Create resource group for the AKS Cluster nodes and associated resources.
module resourceGroup 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: resourceGroupName
  params: {
    name: resourceGroupName
    location: location
  }
}
output resourceGroupName string = resourceGroup.outputs.name

//// deploy the cosmosdb and its virtual network
module vnetDatabase './01-Database/main.bicep' = {
  name: 'vnetDatabase${UniqueString}'
  params: {
    rgName: resourceGroup.name
    vnetname: vnetname
    vnetaddressprefixes: vnetaddressprefixes
    subnets: subnets
    cosmosdbname: cosmosdbname
  }
}
output cosmosDbName string = vnetDatabase.outputs.cosmosDbName


  //// deploy the AKS and its supporting resources
@description('The name of the Azure Container Registry.')
param acrname string = 'akssupporting${UniqueString}'

module aksSupporting '02-AKS-Supporting/main.bicep' = {
  name: acrname
  params: {
    rgName: resourceGroup.name
    acrname: acrname
  }
}

output acrResourceId string = aksSupporting.outputs.acrResourceId
output acrUrl string = aksSupporting.outputs.acrUrl
output acrName string = aksSupporting.outputs.acrName


/// deploy AKS cluster for region 1

@description('The object ID of the Entra ID group for AKS cluster admins.')
param aksAdminsGroupId string

@description('Optional. The AKS cluster SKU name. Set to "Automatic" for AKS Automatic mode, or "Base" for standard mode.')
@allowed([
  'Base'
  'Automatic'
])
param aksSkuName string = 'Base'

module aksCluster '03-AKSCluster-Region1/main.bicep' = {
  name: 'aksCluster${UniqueString}'
  params: {
    aksAdminsGroupId:aksAdminsGroupId
    AKSvnetSubnetID: vnetDatabase.outputs.AKSSubnetResourceId
    rgName: resourceGroup.name
    aksSkuName: aksSkuName
  }
}
output firstoidcIssuerUrl string = aksCluster.outputs.firstoidcIssuerUrl
output firstAKSCluseterName string = aksCluster.outputs.firstAKSCluseterName


/// deploy the AKS cluster for region 2
@description('The Azure region for the second AKS cluster.')
param secondLocation string

@description('The subnet definitions for the second region VNet.')
param secondSubnet array

@description('The address prefixes for the second region VNet.')
param secondvnetaddressprefixes array

@description('The name of the virtual network in the second region.')
param secondVnetName string

module aksClusterRegion2 '04-AKSCluster-Region2/main.bicep' = {
  name: 'aksClusterRegion2${UniqueString}'
  params: {
    clusterDbVnetResourceId:vnetDatabase.outputs.clusterDbVnetResourceId
    aksAdminsGroupId:aksAdminsGroupId
    secondLocation: secondLocation
    rgName: resourceGroupName
    secondSubnet: secondSubnet
    secondvnetaddressprefixes: secondvnetaddressprefixes
    secondVnetName: secondVnetName
    aksSkuName: aksSkuName
  }
}
output secondoidcIssuerUrl string = aksClusterRegion2.outputs.secondoidcIssuerUrl
output secondAKSCluseterName string = aksClusterRegion2.outputs.secondAKSCluseterName
output rgSecondClusterName string = aksClusterRegion2.outputs.rgSecondClusterName

// deploy workload identity
module cosmosWorkloadIdentity './06-WorkloadIdentity/main.bicep' = {
  name: 'aksWorkloadIdentity${UniqueString}'
  params: {
    rgName: resourceGroup.name
    workloadIdentityName: 'aksWorkloadIdentity'

  }
}
output workloadIdentityResourceId string = cosmosWorkloadIdentity.outputs.workloadIdentityresourceId
output workloadIdentityObjectId string = cosmosWorkloadIdentity.outputs.workloadIdentityObjectId
output workloadIdentityClientId string = cosmosWorkloadIdentity.outputs.workloadIdentityClientId
output workloadIdentityName string = cosmosWorkloadIdentity.outputs.workloadIdentityName
