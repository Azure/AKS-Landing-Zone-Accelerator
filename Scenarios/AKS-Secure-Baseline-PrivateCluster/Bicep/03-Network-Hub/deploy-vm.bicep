
targetScope = 'subscription'

param rgName string
param vnetSubnetName string
param vnetName string
param pubkeydata string
param vmSize string
param location string = deployment().location
param adminUsername string
param adminPassword string

resource subnetVM 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  scope: resourceGroup(rgName)
  name: '${vnetName}/${vnetSubnetName}'
}

module jumpbox 'modules/VM/virtualmachine.bicep' = {
  scope: resourceGroup(rgName)
  name: 'jumpbox'
  params: {
    location: location
    subnetId: subnetVM.id
    publicKey: pubkeydata
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
  }
}
