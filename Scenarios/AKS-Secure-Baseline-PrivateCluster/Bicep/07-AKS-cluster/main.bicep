targetScope = 'subscription'

param rgName string
param aadGroupdIds array
param clusterName string
param akslaWorkspaceName string
param vnetName string
param subnetName string
param appGatewayName string
param aksuseraccessprincipalId string
param aksadminaccessprincipalId string

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

module acraksaccess 'modules/Identity/role.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'acraksaccess'
  params: {
    principalId: aksIdentity.outputs.principalId
    roleGuid: '7f951dda-4ed3-4680-a7ca-43fe172d538d' //AcrPull
  }
}

module aksuseraccess 'modules/Identity/role.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksuseraccess'
  params: {
    principalId: aksuseraccessprincipalId
    roleGuid: '4abbcc35-e782-43d8-92c5-2d3f1bd2253f' //Azure Kubernetes Service Cluster User Role
  }
}

module aksadminaccess 'modules/Identity/role.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'aksadminaccess'
  params: {
    principalId: aksadminaccessprincipalId
    roleGuid: '0ab0b1a8-8aac-4efd-b8c2-3ee1fb270be8' //Azure Kubernetes Service Cluster Admin Role
  }
}

// stopped adding the AppGW permission
