param clusterName string
param logworkspaceid string
param privateDNSZoneId string
param aadGroupdIds array
param subnetId string
param identity object
param appGatewayResourceId string
param kubernetesVersion string

@allowed([
  'azure'
  'kubenet'
])
param networkPlugin string = 'azure'
//param appGatewayIdentityResourceId string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2021-07-01' = {
  name: clusterName
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: identity
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    nodeResourceGroup: '${clusterName}-aksInfraRG'
    podIdentityProfile: networkPlugin == 'azure' ?{
      enabled: true
    }:{
      enabled: true
      allowNetworkPluginKubenet: true
    }
    dnsPrefix: '${clusterName}aks'
    agentPoolProfiles: [
      {
        name: 'defaultpool'
        mode: 'System'
        count: 3
        vmSize: 'Standard_DS2_v2'
        osDiskSizeGB: 30
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId
      }
    ]
    networkProfile: networkPlugin == 'azure' ? {
      networkPlugin: 'azure'
      outboundType: 'userDefinedRouting'
      dockerBridgeCidr: '172.16.1.1/30'
      dnsServiceIP: '192.168.100.10'
      serviceCidr: '192.168.100.0/24'
      networkPolicy: 'calico'
    }:{
      networkPlugin: 'kubenet'
      outboundType: 'userDefinedRouting'
      dockerBridgeCidr: '172.16.1.1/30'
      dnsServiceIP: '192.168.100.10'
      serviceCidr: '192.168.100.0/24'
      networkPolicy: 'calico'      
      podCidr: '172.17.0.0/16'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
      privateDNSZone: privateDNSZoneId
    }
    enableRBAC: true
    aadProfile: {
      adminGroupObjectIDs: aadGroupdIds
      enableAzureRBAC: true
      managed: true
      tenantID: subscription().tenantId
    }
    addonProfiles: {
      omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: logworkspaceid
        }
        enabled: true
      }
      azurepolicy: {
        enabled: true
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: appGatewayResourceId
          effectiveApplicationGatewayId: appGatewayResourceId
        }
      }
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
    }
  }
}

output kubeletIdentity string = aksCluster.properties.identityProfile.kubeletidentity.objectId
output ingressIdentity string = aksCluster.properties.addonProfiles.ingressApplicationGateway.identity.objectId
output keyvaultaddonIdentity string = aksCluster.properties.addonProfiles.azureKeyvaultSecretsProvider.identity.objectId
