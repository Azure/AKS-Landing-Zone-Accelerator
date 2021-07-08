targetScope = 'subscription'

@description('Required. The name of the Resource Group')
param resourceGroupNames array = [
  'aks_re1'
  'agw_re1'
  'vnet_hub_re1'
  'aks_spoke_re1'
  'ops_re1'
  'devops_re1'
  'jumpbox_re1'
]

@description('Optional. Location of the Resource Group. It uses the deployment\'s location when not provided.')
param location string = deployment().location

@description('Optional. Switch to lock resource group from deletion.')
param lockForDeletion bool = false

@description('Optional. Tags of the resource group.')
param tags object = {}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2019-05-01' = [for resourceGroupName in resourceGroupNames: {
  location: location
  name: resourceGroupName
  tags: tags
  properties: {}
}]

/*resource lockResource 'Microsoft.Authorization/locks@2016-09-01' = if (lockForDeletion == true) {
  name: '${resourceGroupName}-lock'
  properties: {
    level: 'CanNotDelete'
  }
}
*/
