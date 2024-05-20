targetScope = 'subscription'

param timestamp string = utcNow()
param UniqueString string = uniqueString(subscription().subscriptionId, resourceGroupName, timestamp)
param resourceGroupName string = 'SimpleEcomRG'
param location string = deployment().location


/// Deployment for the cosmosdb and its virtual network (01-Database/main.bicep)
param cosmosdbname string = 'cosmosdb${UniqueString}'
param subnets array
param vnetaddressprefixes array
param vnetname string

  // Create resource group for the AKS Cluster nodes and associated resources.
module resourceGroup 'br/public:avm/res/resources/resource-group:0.2.3' = {
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

param aksAdminsGroupId string

module aksCluster '03-AKSCluster-Region1/main.bicep' = {
  name: 'aksCluster${UniqueString}'
  params: {
    aksAdminsGroupId:aksAdminsGroupId
    AKSvnetSubnetID: vnetDatabase.outputs.AKSSubnetResourceId
    rgName: resourceGroup.name
  }
}
output firstoidcIssuerUrl string = aksCluster.outputs.firstoidcIssuerUrl
output firstAKSCluseterName string = aksCluster.outputs.firstAKSCluseterName


/// deploy the AKS cluster for region 2
param secondLocation string 
param secondSubnet array
param secondvnetaddressprefixes array
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
