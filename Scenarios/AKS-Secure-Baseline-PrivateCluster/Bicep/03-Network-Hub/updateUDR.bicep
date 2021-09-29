targetScope = 'subscription'

param vmVnetName string
param vmVNetSubnetName string
param rtVMSubnetName string
param rgName string

resource subnetVM 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rgName)
  name: '${vmVnetName}/${vmVNetSubnetName}'
}

resource rtVM 'Microsoft.Network/routeTables@2021-02-01' existing ={
  scope: resourceGroup(rgName)
  name: rtVMSubnetName
}

module updateUDR 'modules/vnet/subnet.bicep' = {
  scope: resourceGroup(rgName)
  name: 'updateUDR'
  params: {
    subnetName: vmVNetSubnetName
    vnetName: vmVnetName
    properties: {
      addressPrefix: subnetVM.properties.addressPrefix
      routeTable: {
        id: rtVM.id
      }
    }
  }
}
