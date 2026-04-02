targetScope = 'subscription'

@description('The name of the resource group for the spoke network.')
param rgName string

@description('The name of the spoke virtual network.')
param vnetSpokeName string

@description('The address prefixes for the spoke virtual network.')
param spokeVnetAddPrefixes array

@description('The name of the route table for the AKS subnet.')
param rtAksSubnetName string

@description('The private IP address of the Azure Firewall in the hub network.')
param firewallIp string

@description('The name of the hub virtual network for peering.')
param vnetHubName string

@description('The name of the Application Gateway for Containers traffic controller.')
param agcName string

@description('The name of the resource group containing the hub VNet.')
param vnetHubRgName string

@description('The name of the NSG for the AKS subnet.')
param nsgAksName string

@description('Enable AKS private cluster with private DNS zone.')
param enablePrivateCluster bool = true

@description('The Azure region for all resources.')
param location string = deployment().location

@description('Additional security rules for the AKS NSG.')
param securityRules array = []

@description('The address prefix for the default subnet.')
param spokeSubnetDefaultPrefix string = '10.1.0.0/24'

@description('The address prefix for the AKS subnet.')
param spokeSubnetAksPrefix string = '10.1.1.0/24'

@description('The address prefix for the AGC delegated subnet.')
param spokeSubnetAgcPrefix string = '10.1.2.0/24'

@description('The address prefix for the VM subnet.')
param spokeSubnetVmPrefix string = '10.1.3.0/24'

@description('The address prefix for the private link services subnet.')
param spokeSubnetPLinkervicePrefix string = '10.1.4.0/24'

@description('The address prefix for the AKS API server VNet integration subnet.')
param spokeSubnetApiServerPrefix string = '10.1.5.0/28'

@description('The name of the peering from spoke to hub VNet.')
param remotePeeringName string = 'spoke-hub-peering'

@description('The VM size for the jumpbox virtual machine.')
param vmSize string = 'Standard_DS2_v2'

// Auto-detect zone support for VMs in this region
var vmZones = pickZones('Microsoft.Compute', 'virtualMachines', location, 1)

@secure()
@description('The admin password for the jumpbox VM.')
param jumpboxAdminPassword string

var privateDnsZoneAksSuffixes = {
  AzureCloud: '.azmk8s.io'
  AzureUSGovernment: '.cx.aks.containerservice.azure.us'
  AzureChinaCloud: '.cx.prod.service.azk8s.cn'
  AzureGermanCloud: '' //TODO: what is the correct value here?
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2025-05-01' existing = {
  scope: resourceGroup(vnetHubRgName)
  name: vnetHubName
}

module rg 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module vnetSpoke 'br/public:avm/res/network/virtual-network:0.7.2' = {
  scope: resourceGroup(rg.name)
  name: vnetSpokeName
  params: {
    addressPrefixes: spokeVnetAddPrefixes
    name: vnetSpokeName
    location: location
    subnets: [
      {
        name: 'default'
        addressPrefix: spokeSubnetDefaultPrefix
      }
      {
        name: 'AKS'
        addressPrefix: spokeSubnetAksPrefix
        routeTableResourceId: routeTable.outputs.resourceId
        networkSecurityGroupResourceId: networkSecurityGroupAks.outputs.resourceId
      }
      {
        name: 'AGCSubnet'
        addressPrefix: spokeSubnetAgcPrefix
        delegation: 'Microsoft.ServiceNetworking/trafficControllers'
      }
      {
        name: 'vmsubnet'
        addressPrefix: spokeSubnetVmPrefix
      }
      {
        name: 'servicespe'
        addressPrefix: spokeSubnetPLinkervicePrefix
      }
      {
        name: 'apiserver-subnet'
        addressPrefix: spokeSubnetApiServerPrefix
        delegation: 'Microsoft.ContainerService/managedClusters'
      }
    ]
    enableTelemetry: true
    peerings: [
      {
        allowForwardedTraffic: true
        allowGatewayTransit: false
        allowVirtualNetworkAccess: true
        remotePeeringAllowForwardedTraffic: true
        remotePeeringAllowVirtualNetworkAccess: true
        remotePeeringEnabled: true
        remotePeeringName: remotePeeringName
        remoteVirtualNetworkResourceId: vnetHub.id
        useRemoteGateways: false
      }
    ]
  }
  dependsOn: []
}

module networkSecurityGroupAks 'br/public:avm/res/network/network-security-group:0.5.2' = {
  scope: resourceGroup(rg.name)
  name: nsgAksName
  params: {
    name: nsgAksName
    location: location
    securityRules: securityRules
    enableTelemetry: true
  }
}



module routeTable 'br/public:avm/res/network/route-table:0.5.0' = {
  scope: resourceGroup(rg.name)
  name: rtAksSubnetName
  params: {
    name: rtAksSubnetName
    location: location
    routes: [
      {
        name: 'vm-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: firewallIp
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneAcr 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsACRZone'
  params: {
    name: 'privatelink${environment().suffixes.acrLoginServer}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnetHub.id
      }
      {
        virtualNetworkResourceId: vnetSpoke.outputs.resourceId
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneKv 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsKVZone'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnetHub.id
      }
      {
        virtualNetworkResourceId: vnetSpoke.outputs.resourceId
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneSa 'br/public:avm/res/network/private-dns-zone:0.8.1' = {
  scope: resourceGroup(rg.name)
  name: 'privatednsSAZone'
  params: {
    name: 'privatelink.file.${environment().suffixes.storage}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnetHub.id
      }
    ]
    enableTelemetry: true
  }
}

module privateDnsZoneAks 'br/public:avm/res/network/private-dns-zone:0.8.1' = if (enablePrivateCluster) {
  scope: resourceGroup(rg.name)
  name: 'privatednsAKSZone'
  params: {
    name: 'privatelink.${toLower(location)}${privateDnsZoneAksSuffixes[environment().name]}'
    location: 'global'
    virtualNetworkLinks: [
      {
        virtualNetworkResourceId: vnetHub.id
      }
    ]
    enableTelemetry: true
  }
}

// ===================== //
// Application Gateway   //
// for Containers (AGC)  //
// ===================== //
module agc 'agc.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'agcDeployment'
  params: {
    agcName: agcName
    location: location
    agcSubnetId: vnetSpoke.outputs.subnetResourceIds[2] // AGCSubnet
  }
}

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.5.0' = {
  scope: resourceGroup(rg.name)
  name: 'id-aks'
  params: {
    name: 'id-aks'
    location: location
  }
}

module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.21.0' = {
  scope: resourceGroup(rg.name)
  name: 'virtualMachineDeployment'
  params: {
    // Required parameters
    adminUsername: 'azureuser'
    imageReference: {
      offer: '0001-com-ubuntu-server-jammy'
      publisher: 'Canonical'
      sku: '22_04-lts-gen2'
      version: 'latest'
    }
    name: 'vm-jumpbox'
    nicConfigurations: [
      {
        ipConfigurations: [
          {
            name: 'ipconfig01'
            pipConfiguration: {
              name: 'pip-01'
            }
            subnetResourceId: vnetSpoke.outputs.subnetResourceIds[3]
          }
        ]
        nicSuffix: '-nic-01'
      }
    ]
    osDisk: {
      caching: 'ReadWrite'
      diskSizeGB: 128
      managedDisk: {
        storageAccountType: 'Premium_LRS'
      }
    }
    osType: 'Linux'
    vmSize: vmSize
    availabilityZone: length(vmZones) > 0 ? int(vmZones[0]) : -1
    // Non-required parameters
    disablePasswordAuthentication: false
    adminPassword: jumpboxAdminPassword
    location: location
    managedIdentities: {
      systemAssigned: true
    }
  }
}

@description('The resource ID of the API server VNet integration subnet.')
output apiServerSubnetId string = vnetSpoke.outputs.subnetResourceIds[5] // apiserver-subnet

@description('The principal ID of the jumpbox VM system-assigned managed identity.')
output jumpboxPrincipalId string = virtualMachine.outputs.?systemAssignedMIPrincipalId ?? ''
