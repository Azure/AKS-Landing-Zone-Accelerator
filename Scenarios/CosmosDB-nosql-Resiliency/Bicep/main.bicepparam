using 'main.bicep'

param vnetaddressprefixes = [
  '10.2.0.0/16'
]

param vnetname = 'AKSClusterRegion1VNet'

param subnets = [
  {
    addressPrefix: '10.2.0.0/24'
    name: 'datasubnet'
    serviceEndpoints: [
      {
        service: 'Microsoft.AzureCosmosDB'
      }
    ]
  }
  {
    addressPrefix: '10.2.1.0/24'
    name: 'aksregiononesubnet'
  }
]

param secondvnetaddressprefixes = [
  '10.1.0.0/16'
]

param secondVnetName = 'AKSClusterRegion2VNet'

param secondSubnet = [
  {
    addressPrefix: '10.1.0.0/24'
    name: 'secondclustersubnet'
  }
]

param aksAdminsGroupId = '<REPLACE_WITH_ENTRA_ID_GROUP_OBJECT_ID>'

param secondLocation = '<REPLACE_WITH_SECOND_REGION>'
