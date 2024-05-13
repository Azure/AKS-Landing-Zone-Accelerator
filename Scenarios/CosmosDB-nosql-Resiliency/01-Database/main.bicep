targetScope = 'subscription'

param location string = deployment().location
param rgname string
param vnetname string
param subnets array
param vnetaddressprefixes array
param cosmosdbname string = 'cosmosdb-${uniqueString(subscription().subscriptionId)}'

// Resource group to hold all database related resources
module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgname
  params: {
    name: rgname
    location: location
  }
}

// Main VNet with single subnet
module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.6' = {
  name: 'virtualNetworkDeployment'
  scope: resourceGroup(rg.name)
  dependsOn: [rg]
  params: {
    // Required parameters
    addressPrefixes: vnetaddressprefixes
    subnets: subnets
    name: vnetname
  }
}

// CosmosDB with private endpoint on VNet
module databaseAccount 'br/public:avm/res/document-db/database-account:0.5.1' = {
  scope: resourceGroup(rg.name)
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

output cosmosDbVnetResourceId string = virtualNetwork.outputs.resourceId
output cosmosDbName string = cosmosdbname
