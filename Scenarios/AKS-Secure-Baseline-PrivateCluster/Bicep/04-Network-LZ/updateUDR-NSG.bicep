targetScope = 'subscription'

param spokeVnetName string
param aksVNetSubnetName string
param rtAKSSubnetName string
param rgName string
param nsgAKSName string
param appGatewaySubnetName string
param nsgAppGWName string

resource subnetAKS 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rgName)
  name: '${spokeVnetName}/${aksVNetSubnetName}'
}

resource rtVM 'Microsoft.Network/routeTables@2021-02-01' existing ={
  scope: resourceGroup(rgName)
  name: rtAKSSubnetName
}

resource nsgaks 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  scope: resourceGroup(rgName)
  name: nsgAKSName
}

module updateUDR 'modules/vnet/subnet.bicep' = {
  scope: resourceGroup(rgName)
  name: 'updateUDR'
  params: {
    subnetName: aksVNetSubnetName
    vnetName: spokeVnetName
    properties: {
      addressPrefix: subnetAKS.properties.addressPrefix
      routeTable: {
        id: rtVM.id
      }
      networkSecurityGroup: {
        id: nsgaks.id
      }      
    }
  }
}

resource subnetAPPGW 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rgName)
  name: '${spokeVnetName}/${appGatewaySubnetName}'
}

resource nsgAppGW 'Microsoft.Network/networkSecurityGroups@2021-02-01' existing = {
  scope: resourceGroup(rgName)
  name: nsgAppGWName
}

module updateNSGUDRAPPGW 'modules/vnet/subnet.bicep' = {
  scope: resourceGroup(rgName)
  name: 'updateNSGAPPGW'
  params: {
    subnetName: appGatewaySubnetName
    vnetName: spokeVnetName
    properties: {
      addressPrefix: subnetAPPGW.properties.addressPrefix
      networkSecurityGroup: {
        id: nsgAppGW.id
      }
    }
  }
}

// module updateNSGUDR 'modules/vnet/subnet.bicep' = {
//   scope: resourceGroup(rg.name)
//   name: 'updateNSGUDR'
//   params: {
//     subnetName: aksVNetSubnetName
//     vnetName: vnetSpokeName
//     properties: {
//       addressPrefix: aksSubnet.properties.addressPrefix
//       routeTable: {
//         id: routetable.outputs.routetableID
//       }
//       networkSecurityGroup: {
//         id: nsgakssubnet.outputs.nsgID
//       }
//     }
//   }
// }
