/////////////////
// Global Parameters
/////////////////
targetScope = 'subscription'
// param location string = deployment().location

//////////////////////////////////
//////////////////////////////////
// PARAMETERS
//////////////////////////////////
//////////////////////////////////

/////////////////
// 03-network-Hub
/////////////////
param rgHubName string = 'AKS-LZA-HUB'
param vnetHubName string = 'VNet-HUB'
param hubVNETaddPrefixes array = ['10.0.0.0/16']
param azfwName string = 'AZFW'
param rtVMSubnetName string = 'vm-subnet-rt'
param fwapplicationRuleCollections array = [
  {
    name: 'Helper-tools'
    properties: {
      priority: 101
      action: {
        type: 'Allow'
      }
      rules: [
        {
          name: 'Allow-ifconfig'
          protocols: [
            {
              port: 80
              protocolType: 'Http'
            }
            {
              port: 443
              protocolType: 'Https'
            }
          ]
          targetFqdns: [
            'ifconfig.co'
            'api.snapcraft.io'
            'jsonip.com'
            'kubernaut.io'
            'motd.ubuntu.com'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
        }
      ]
    }
  }
  {
    name: 'AKS-egress-application'
    properties: {
      priority: 102
      action: {
        type: 'Allow'
      }
      rules: [
        {
          name: 'Egress'
          protocols: [
            {
              port: 443
              protocolType: 'Https'
            }
          ]
          targetFqdns: [
            '*.azmk8s.io'
            'aksrepos.azurecr.io'
            '*.blob.core.windows.net'
            '*.cdn.mscr.io'
            '*.opinsights.azure.com'
            '*.monitoring.azure.com'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
        }
        {
          name: 'Registries'
          protocols: [
            {
              port: 443
              protocolType: 'Https'
            }
          ]
          targetFqdns: [
            '*.azurecr.io'
            '*.gcr.io'
            '*.docker.io'
            'quay.io'
            '*.quay.io'
            '*.cloudfront.net'
            'production.cloudflare.docker.com'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
        }
        {
          name: 'Additional-Usefull-Address'
          protocols: [
            {
              port: 443
              protocolType: 'Https'
            }
          ]
          targetFqdns: [
            'grafana.net'
            'grafana.com'
            'stats.grafana.org'
            'github.com'
            'charts.bitnami.com'
            'raw.githubusercontent.com'
            '*.letsencrypt.org'
            'usage.projectcalico.org'
            'vortex.data.microsoft.com'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
        }
        {
          name: 'AKS-FQDN-TAG'
          protocols: [
            {
              port: 80
              protocolType: 'Http'
            }
            {
              port: 443
              protocolType: 'Https'
            }
          ]
          targetFqdns: []
          fqdnTags: [
            'AzureKubernetesService'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
        }
      ]
    }
  }
]
param fwnetworkRuleCollections array = [
  {
    name: 'AKS-egress'
    properties: {
      priority: 200
      action: {
        type: 'Allow'
      }
      rules: [
        {
          name: 'NTP'
          protocols: [
            'UDP'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
          destinationAddresses: [
            '*'
          ]
          destinationPorts: [
            '123'
          ]
        }
        {
          name: 'APITCP'
          protocols: [
            'TCP'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
          destinationAddresses: [
            '*'
          ]
          destinationPorts: [
            '9000'
          ]
        }
        {
          name: 'APIUDP'
          protocols: [
            'UDP'
          ]
          sourceAddresses: [
            '10.1.1.0/24'
          ]
          destinationAddresses: [
            '*'
          ]
          destinationPorts: [
            '1194'
          ]
        }
      ]
    }
  }
]
param fwnatRuleCollections array = []
param availabilityZones array = ['1', '2', '3']

/////////////////
// 04-Network-LZ
/////////////////

param rgSpokeName string = 'AKS-LZA-SPOKE'
//param vnetSpokeName string = 'VNet-SPOKE'
//param availabilityZones array = ['1', '2', '3']
param spokeVNETaddPrefixes array = ['10.1.0.0/16']
param rtAKSSubnetName string = 'AKS-RT'
param firewallIP string = '10.0.1.4'
//param vnetHubName string = 'VNet-HUB'
param appGatewayName string = 'APPGW'
param vnetHUBRGName string = 'AKS-LZA-HUB'
param nsgAKSName string = 'AKS-NSG'
param nsgAppGWName string = 'APPGW-NSG'
param rtAppGWSubnetName string = 'AppGWSubnet-RT'
param dnsServers array = []
param appGwyAutoScale object = { value: { maxCapacity: 2, minCapacity: 1 } }
param securityRules array = []

/////////////////
// 05-AKS-Supporting
/////////////////

//param rgSpokeName string = 'AKS-LZA-SPOKE'
param vnetSpokeName string = 'VNet-SPOKE'
param subnetName string = 'servicespe'
param privateDNSZoneACRName string = 'privatelink${environment().suffixes.acrLoginServer}'
param privateDNSZoneKVName string = 'privatelink.vaultcore.azure.net'
param privateDNSZoneSAName string = 'privatelink.file.${environment().suffixes.storage}'
param acrName string = 'eslzacr${uniqueString('acrvws', uniqueString(subscription().id))}'
param keyvaultName string = 'eslz-kv-${uniqueString('acrvws', uniqueString(subscription().id))}'
param storageAccountName string = 'eslzsa${uniqueString('aks', uniqueString(subscription().id))}'
param storageAccountType string = 'Standard_GZRS'

/////////////////
// 06-AKS-Cluster
/////////////////

//param rgSpokeName string = 'AKS-LZA-SPOKE'
//param vnetSpokeName string = 'VNet-SPOKE'
param aksSubnetName string = 'AKS'
//param appGatewayName string = 'APPGW'
param aksIdentityName string = 'aksIdentity'
//param location: deployment().location
param enableAutoScaling bool = true
param autoScalingProfile object = {
  balanceSimilarNodeGroups: 'false'
  expander: 'random'
  maxEmptyBulkDelete: '10'
  maxGracefulTerminationSec: '600'
  maxNodeProvisionTime: '15m'
  maxTotalUnreadyPercentage: '45'
  newPodScaleUpDelay: '0s'
  okTotalUnreadyCount: '3'
  scaleDownDelayAfterAdd: '10m'
  scaleDownDelayAfterDelete: '10s'
  scaleDownDelayAfterFailure: '3m'
  scaleDownUnneededTime: '10m'
  scaleDownUnreadyTime: '20m'
  scaleDownUtilizationThreshold: '0.5'
  scanInterval: '10s'
  skipNodesWithLocalStorage: 'false'
  skipNodesWithSystemPods: 'true'
}
param aksadminaccessprincipalId string = ''
param kubernetesVersion string = '1.30'
//param keyvaultName string = 'eslz-kv-${uniqueString('acrvws', uniqueString(subscription().id))}'
param networkPlugin string = 'azure'

//////////////////////////////////
//////////////////////////////////
// MODULES
//////////////////////////////////
//////////////////////////////////


/////////////////
// 03-network-Hub
/////////////////

module networkHub '../Bicep/03-Network-Hub/main.bicep' = {
  name: 'hubDeploy'
  params: {
    rgName: rgHubName
    availabilityZones: availabilityZones
    vnetHubName: vnetHubName
    hubVNETaddPrefixes: hubVNETaddPrefixes
    azfwName: azfwName
    rtVMSubnetName: rtVMSubnetName
    fwapplicationRuleCollections: fwapplicationRuleCollections
    fwnetworkRuleCollections: fwnetworkRuleCollections
    fwnatRuleCollections: fwnatRuleCollections
  }
}

// /////////////////
// // 04-Network-LZ
// /////////////////

// module networkSpoke '../Bicep/04-Network-LZ/main.bicep' = {
//   name: 'landingZoneDeploy'
//   params: {
//     rgName: rgSpokeName
//     vnetSpokeName: vnetSpokeName
//     availabilityZones: availabilityZones
//     spokeVNETaddPrefixes: spokeVNETaddPrefixes
//     rtAKSSubnetName: rtAKSSubnetName
//     firewallIP: firewallIP
//     vnetHubName: vnetHubName
//     appGatewayName: appGatewayName
//     vnetHUBRGName: vnetHUBRGName
//     nsgAKSName: nsgAKSName
//     nsgAppGWName: nsgAppGWName
//     rtAppGWSubnetName: rtAppGWSubnetName
//     dnsServers: dnsServers
//     appGwyAutoScale: appGwyAutoScale
//     securityRules: securityRules
//   }
//   dependsOn: [networkHub]
// }

// /////////////////
// // 05-AKS-Supporting
// /////////////////

// module aksSupporting '../Bicep/05-AKS-Supporting/main.bicep' = {
//   name: 'aksSupporting'
//   params: {
//     rgName: rgSpokeName
//     vnetName: vnetSpokeName
//     subnetName: subnetName
//     privateDNSZoneACRName: privateDNSZoneACRName
//     privateDNSZoneKVName: privateDNSZoneKVName
//     privateDNSZoneSAName: privateDNSZoneSAName
//     acrName: acrName
//     keyvaultName: keyvaultName
//     storageAccountName: storageAccountName
//     storageAccountType: storageAccountType
//   }
//   dependsOn: [networkSpoke]
// }

// /////////////////
// // 06-AKS-Cluster
// /////////////////

// module aksCluster '../Bicep/06-AKS-Cluster/main.bicep' = {
//   name: 'aksCluster'
//   params: {
//     rgName: rgSpokeName
//     vnetName: vnetSpokeName
//     subnetName: aksSubnetName
//     appGatewayName: appGatewayName
//     aksIdentityName: aksIdentityName
//     //location: deployment().location
//     enableAutoScaling: enableAutoScaling
//     autoScalingProfile: autoScalingProfile
//     aksadminaccessprincipalId: aksadminaccessprincipalId
//     kubernetesVersion: kubernetesVersion
//     keyvaultName: keyvaultName
//     networkPlugin: networkPlugin
//   }
//   dependsOn: [aksSupporting]
// }
