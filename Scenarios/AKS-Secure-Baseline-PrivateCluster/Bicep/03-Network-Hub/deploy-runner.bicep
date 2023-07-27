
targetScope = 'subscription'

param rgName string
param vnetSubnetName string
param vnetName string
param vmName string = 'runner'
param vmSize string
param publisher string = 'Canonical'
param offer string = '0001-com-ubuntu-server-focal'
param sku string = '20_04-lts-gen2'
param location string = deployment().location
param adminUsername string
@secure()
param adminPassword string
@secure()
param ghtoken string

resource subnetVM 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' existing = {
  scope: resourceGroup(rgName)
  name: '${vnetName}/${vnetSubnetName}'
}

module jumpbox 'modules/VM/runner.bicep' = {
  scope: resourceGroup(rgName)
  name: vmName
  params: {
    location: location
    subnetId: subnetVM.id
    vmSize: vmSize
    publisher: publisher
    offer: offer
    sku: sku
    adminUsername: adminUsername
    adminPassword: adminPassword
    ghtoken: ghtoken
    vmName: vmName 
  }
}
