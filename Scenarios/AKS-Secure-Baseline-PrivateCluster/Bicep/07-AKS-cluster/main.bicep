targetScope = 'subscription'

param rgName string
param aadGroupdIds array
param clusterName string
param akslaWorkspaceName string
param vnetName string
param subnetName string
param appGatewayName string

module rg 'modules/resource-group/rg.bicep' = {
  name: rgName
  params: {
    rgName: rgName
    location: deployment().location
  }
}

module aksIdentity 'modules/Identity/userassigned.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksIdentity'
  params: {
    identityName: 'aksIdentity'
  }
}

module appGatewayIdentity 'modules/Identity/userassigned.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'appGatewayIdentity'
  params: {
    identityName: 'appGatewayIdentity'
  }
}

resource pvtdnsAKSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: 'privatelink.${toLower(deployment().location)}.azmk8s.io'
  scope: resourceGroup(rg.name)
}

module akslaworkspace 'modules/laworkspace/la.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'akslaworkspace'
  params: {
    workspaceName: akslaWorkspaceName
  }
}

resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: '${vnetName}/${subnetName}'
}

resource appGateway 'Microsoft.Network/applicationGateways@2021-02-01' existing = {
  scope: resourceGroup(rg.name)
  name: appGatewayName
}

module aksPvtDNSContrib 'modules/Identity/role.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksPvtDNSContrib'
  params: {
    principalId: aksIdentity.outputs.principalId
    roleGuid: 'b12aa53e-6015-4669-85d0-8515ebb3ae7f' //Private DNS Zone Contributor
  }
}

module aksPvtNetworkContrib 'modules/Identity/role.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksPvtNetworkContrib'
  params: {
    principalId: aksIdentity.outputs.principalId
    roleGuid: '4d97b98b-1d4f-4787-a291-c67834d212e7' //Network Contributor
  }
}

module aksCluster 'modules/aks/privateaks.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksCluster'
  params: {
    aadGroupdIds: aadGroupdIds
    clusterName: clusterName
    logworkspaceid: akslaworkspace.outputs.laworkspaceId
    privateDNSZoneId: pvtdnsAKSZone.id
    subnetId: aksSubnet.id
    identity: {
      '${aksIdentity.outputs.identityid}' : {}
    }
    appGatewayResourceId: appGateway.id
  }
  dependsOn: [
    aksPvtDNSContrib
    aksPvtNetworkContrib
  ]
}
