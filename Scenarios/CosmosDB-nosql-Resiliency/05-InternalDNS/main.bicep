targetScope = 'subscription'

param rgname string
param location string = deployment().location
param cosmosdbname string
param aksClusterVnetRegion1ResourceId string
param aksClusterVnetRegion2ResourceId string

// Resource group to hold all database related resources
module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgname
  params: {
    name: rgname
    location: location
  }
}

module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.5' = {
  name: 'privateDnsZoneDeployment'
  scope: resourceGroup(rg.name)
  params: {
    // Required parameters
    name: 'documents.azure.com'
    a: [
      {
        aRecords: [
          {
            ipv4Address: '10.0.1.4'
          }
        ]
        name: cosmosdbname
        ttl: 3600
      }
    ]
    virtualNetworkLinks: [
      {
        registrationEnabled: false
        virtualNetworkResourceId: aksClusterVnetRegion1ResourceId
      }
      {
        registrationEnabled: false
        virtualNetworkResourceId: aksClusterVnetRegion2ResourceId
      }
    ]
    location: 'global'
  }
}
