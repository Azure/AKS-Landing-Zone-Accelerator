targetScope = 'subscription'


param UniqueString string = uniqueString(subscription().subscriptionId)
param resourceGroupName string = 'AKSClusterRegion1'
param location string = deployment().location


/// Deployment for the cosmosdb and its virtual network (01-Database/main.bicep)
param cosmosdbname string = 'cosmosdb-${UniqueString}'
param subnets array
param vnetaddressprefixes array
param vnetname string

  // Create resource group for the AKS Cluster nodes and associated resources.
module resourceGroup 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: 'AKSClusterRegion1'
  params: {
    name: resourceGroupName
    location: location
  }
}
output resourceGroupName string = resourceGroup.outputs.name

//// deploy the cosmosdb and its virtual network
module vnetDatabase './01-Database/main.bicep' = {
  name: 'vnetDatabase'
  params: {
    rgName: resourceGroup.name
    vnetname: vnetname
    vnetaddressprefixes: vnetaddressprefixes
    subnets: subnets
    cosmosdbname: cosmosdbname
  }
}
output AKSSubnetResourceId string = vnetDatabase.outputs.AKSSubnetResourceId
output clusterDbVnetResourceId string = vnetDatabase.outputs.clusterDbVnetResourceId

  //// deploy the AKS and its supporting resources
param acrname string = 'akssupporting-${UniqueString}'

module aksSupporting '02-AKS-Supporting/main.bicep' = {
  name: 'aksSupporting'
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
param AKSSubnetResourceId string

module aksCluster '03-AKSCluster-Region1/main.bicep' = {
  name: 'aksCluster'
  params: {
    aksAdminsGroupId:aksAdminsGroupId
    AKSvnetSubnetID: AKSSubnetResourceId
    rgName: resourceGroup.name
  }
}
output firstoidcIssuerUrl string = aksCluster.outputs.firstoidcIssuerUrl
output firstAKSCluseterName string = aksCluster.outputs.firstAKSCluseterName


/// deploy the AKS cluster for region 2
param clusterDbVnetResourceId string
@secure()
param secondLocation string 
param secondSubnet array
param secondvnetaddressprefixes array
param secondVnetName string

module aksClusterRegion2 '04-AKSCluster-Region2/main.bicep' = {
  name: 'aksClusterRegion2'
  params: {
    clusterDbVnetResourceId:clusterDbVnetResourceId
    aksAdminsGroupId:aksAdminsGroupId
    secondLocation: secondLocation
    secondRgName: 'AKSClusterRegion2'
    secondSubnet: secondSubnet
    secondvnetaddressprefixes: secondvnetaddressprefixes
    secondVnetName: secondVnetName
  }
}
output secondoidcIssuerUrl string = aksClusterRegion2.outputs.secondoidcIssuerUrl
output secondAKSCluseterName string = aksClusterRegion2.outputs.secondAKSCluseterName
output rgSecondClusterName string = aksClusterRegion2.outputs.rgSecondClusterName

/// deploy private dns zone
module privateDnsZone '05-InternalDNS/main.bicep' = {
  name: 'privateDnsZone'
  params: {
    rgName: resourceGroup.name
    aksClusterVnetRegion1ResourceId: vnetDatabase.outputs.clusterDbVnetResourceId
    aksClusterVnetRegion2ResourceId: aksClusterRegion2.outputs.aksClusterVnetRegion2ResourceId
    cosmosdbname: vnetDatabase.outputs.cosmosDbName
  }
}

// deploy workload identity
module cosmosWorkloadIdentity './06-WorkloadIdentity/main.bicep' = {
  name: 'aksWorkloadIdentity'
  params: {
    rgName: resourceGroup.name
    workloadIdentityName: 'aksWorkloadIdentity'

  }
}
output workloadIdentityResourceId string = cosmosWorkloadIdentity.outputs.workloadIdentityresourceId
output workloadIdentityObjectId string = cosmosWorkloadIdentity.outputs.workloadIdentityObjectId
output workloadIdentityClientId string = cosmosWorkloadIdentity.outputs.workloadIdentityClientId
output workloadIdentityName string = cosmosWorkloadIdentity.outputs.workloadIdentityName
