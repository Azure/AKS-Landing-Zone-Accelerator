targetScope = 'subscription'

// Parameters
param rgName string
param vnetHubName string
param hubVNETaddPrefixes array
param hubSubnets array
param azfwName string
param rtVMSubnetName string
param fwapplicationRuleCollections array
param fwnetworkRuleCollections array
param fwnatRuleCollections array
param location string = deployment().location
param availabilityZones array
@secure()
param adminPassword string
param adminUsername string
param vmSize string
param pubkeydata string

module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: vnetHubName
  params: {
    addressPrefixes: hubVNETaddPrefixes
    name: vnetHubName
    location: location
    subnets: hubSubnets
    enableTelemetry: true
  }
}

module publicIpFW 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-PIP'
  params: {
    name: 'AZFW-PIP'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicIpFWMgmt 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-Management-PIP'
  params: {
    name: 'AZFW-Management-PIP'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicipbastion 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'publicipbastion'
  params: {
    name: 'publicipbastion'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: 'bastion'
  params: {
    name: 'bastion'
    vNetId: virtualNetwork.outputs.resourceId
    bastionSubnetPublicIpResourceId: publicipbastion.outputs.resourceId
    location: location
    enableTelemetry: true
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.2.2' = {
  scope: resourceGroup(rg.name)
  name: rtVMSubnetName
  params: {
    name: rtVMSubnetName
    location: location
    // routes: [
    //   {
    //     name: 'vm-to-internet'
    //     properties: {
    //       addressPrefix: '0.0.0.0/0'
    //       nextHopIpAddress: azureFirewall.outputs.ipConfiguration.properties.privateIPAddress
    //       nextHopType: 'VirtualAppliance'
    //       enableTelemetry: true
    //     }
    //   }
    // ]
  }
}

module jumpbox 'br/public:avm/res/compute/virtual-machine:0.2.2' = {
  scope:  resourceGroup(rg.name)
  name: 'jumpbox'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSize: vmSize
    osDisk: {
      createOption: 'FromImage'
      diskSizeGB: '128'
      managedDisk: {
        storageAccountType: 'Standard_LRS'
      }
    }
    imageReference: {
      offer: '0001-com-ubuntu-server-focal'
      publisher: 'Canonical'
      sku: '20_04-lts-gen2'
      version: 'latest'
    }
    name: 'jumpbox'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'jbnic'
            subnetResourceId: virtualNetwork.outputs.subnetResourceIds[4]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    location: location
    publicKeys: [
      {
        keyData: pubkeydata
        path: '/home/localAdminUser/.ssh/authorized_keys'
      }
    ]
    osType: 'Linux'
  }
}



// module azureFirewall 'br/public:avm/res/network/azure-firewall:0.1.1' = {
//   name: '${uniqueString(deployment().name, resourceLocation)}-test-nafmin'
//   params: {
//     name: 'nafmin001'
//     location: '<location>'
//     virtualNetworkId: '<virtualNetworkId>'
//   }
// }

