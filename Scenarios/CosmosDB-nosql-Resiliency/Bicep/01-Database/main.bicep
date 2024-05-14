targetScope = 'subscription'

param vnetname string
param subnets array
param vnetaddressprefixes array
param cosmosdbname string 
param rgName string



// Main VNet with single subnet
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'virtualNetworkDeployment'
  scope: resourceGroup(rgName)
  params: {
    // Required parameters
    addressPrefixes: vnetaddressprefixes
    subnets: subnets
    name: vnetname
  }
}

// CosmosDB with private endpoint on VNet
module databaseAccount 'br/public:avm/res/document-db/database-account:0.5.1' = {
  scope: resourceGroup(rgName)
  dependsOn: [virtualNetwork]
  name: 'databaseAccountDeployment'
  params: {
    // Required parameters
    name: cosmosdbname
    networkRestrictions: {
      ipRules: [
        //'79.0.0.0'
        //'80.0.0.0'
      ]
      //networkAclBypass: 'AzureServices'
      publicNetworkAccess: 'Disabled'
      virtualNetworkRules: [
        // {
        //   subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
        // }
      ]
    }
    privateEndpoints: [
      {
        service: 'Sql'
        subnetResourceId: virtualNetwork.outputs.subnetResourceIds[0]
      }
    ]
  }
}

output clusterDbVnetResourceId string = virtualNetwork.outputs.resourceId
output AKSSubnetResourceId string = virtualNetwork.outputs.subnetResourceIds[1]
output cosmosDBResourceId string = databaseAccount.outputs.resourceId
output cosmosDbName string = cosmosdbname
// cosmosDbVnetResourceId
