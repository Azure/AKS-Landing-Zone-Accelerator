targetScope = 'subscription'

param rgName string
param cosmosdbname string
param aksClusterVnetRegion1ResourceId string
param aksClusterVnetRegion2ResourceId string


module privateDnsZone 'br/public:avm/res/network/private-dns-zone:0.2.5' = {
  name: 'privateDnsZoneDeployment'
  scope: resourceGroup(rgName)
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
