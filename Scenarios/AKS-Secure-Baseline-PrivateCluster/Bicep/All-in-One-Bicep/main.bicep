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
param vnetSpokeName string = 'VNet-SPOKE'
//param availabilityZones array = ['1', '2', '3']
param spokeVNETaddPrefixes array = ['10.1.0.0/16']
param rtAKSSubnetName string = 'AKS-RT'
param firewallIP string = '10.0.1.4'
//param vnetHubName string = 'VNet-HUB'
param appGatewayName string = 'APPGW'
//param vnetHUBRGName string = 'AKS-LZA-HUB'
param nsgAKSName string = 'AKS-NSG'
param nsgAppGWName string = 'APPGW-NSG'
param rtAppGWSubnetName string = 'AppGWSubnet-RT'
//param dnsServers array = []
param appGwyAutoScale object = { maxCapacity: 2, minCapacity: 1 }
param securityRules array = []
param defaultSubnetName string = 'default'
param defaultSubnetAddressPrefix string = '10.0.0.0/24'
param azureFirewallSubnetName string = 'AzureFirewallSubnet'
param azureFirewallSubnetAddressPrefix string = '10.0.1.0/26'
param azureFirewallManagementSubnetName string = 'AzureFirewallManagementSubnet'
param azureFirewallManagementSubnetAddressPrefix string = '10.0.4.0/26'
param azureBastionSubnetName string = 'AzureBastionSubnet'
param azureBastionSubnetAddressPrefix string = '10.0.2.0/27'
param vmsubnetSubnetName string = 'vmsubnet'
param vmsubnetSubnetAddressPrefix string = '10.0.3.0/24'

/////////////////
// 05-AKS-Supporting
/////////////////

//param rgSpokeName string = 'AKS-LZA-SPOKE'
//param vnetSpokeName string = 'VNet-SPOKE'
param subnetName string = 'servicespe'
param privateDNSZoneACRName string = 'privatelink${environment().suffixes.acrLoginServer}'
param privateDNSZoneKVName string = 'privatelink.vaultcore.azure.net'
param privateDNSZoneSAName string = 'privatelink.file.${environment().suffixes.storage}'
param storageAccountName string = 'eslzsa${uniqueString('aks', uniqueString(subscription().id, utcNow()))}'
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
param networkPlugin string = 'azure'
param aksClusterName string = 'aksCluster'

//////////////////////////////////
//////////////////////////////////
// MODULES
//////////////////////////////////
//////////////////////////////////


/////////////////
// 03-network-Hub
/////////////////

module networkHub '../03-Network-Hub/main.bicep' = {
  name: 'hubDeploy'
  params: {
    rgName: rgHubName
    availabilityZones: availabilityZones
    vnetHubName: vnetHubName
    azfwName: azfwName
    rtVMSubnetName: rtVMSubnetName
    fwapplicationRuleCollections: fwapplicationRuleCollections
    fwnetworkRuleCollections: fwnetworkRuleCollections
    fwnatRuleCollections: fwnatRuleCollections
    hubVNETaddPrefixes: hubVNETaddPrefixes
    defaultSubnetName: defaultSubnetName
    defaultSubnetAddressPrefix: defaultSubnetAddressPrefix
    azureFirewallSubnetName: azureFirewallSubnetName
    azureFirewallSubnetAddressPrefix: azureFirewallSubnetAddressPrefix
    azureFirewallManagementSubnetName: azureFirewallManagementSubnetName
    azureFirewallManagementSubnetAddressPrefix: azureFirewallManagementSubnetAddressPrefix
    azureBastionSubnetName: azureBastionSubnetName
    azureBastionSubnetAddressPrefix: azureBastionSubnetAddressPrefix
    vmsubnetSubnetName: vmsubnetSubnetName
    vmsubnetSubnetAddressPrefix: vmsubnetSubnetAddressPrefix 
  }
}

/////////////////
// 04-Network-LZ
/////////////////

module networkSpoke '../04-Network-LZ/main.bicep' = {
  name: 'lzSpokeDeploy'
  params: {
    rgName: rgSpokeName
    vnetSpokeName: vnetSpokeName
    availabilityZones: availabilityZones
    spokeVNETaddPrefixes: spokeVNETaddPrefixes
    rtAKSSubnetName: rtAKSSubnetName
    firewallIP: firewallIP
    vnetHubName: vnetHubName
    appGatewayName: appGatewayName
    vnetHUBRGName: rgHubName
    nsgAKSName: nsgAKSName
    nsgAppGWName: nsgAppGWName
    rtAppGWSubnetName: rtAppGWSubnetName
    //dnsServers: dnsServers
    appGwyAutoScale: appGwyAutoScale
    securityRules: securityRules
  }
  dependsOn: [networkHub]
}

/////////////////
// 05-AKS-Supporting
/////////////////

module aksSupporting '../05-AKS-Supporting/main.bicep' = {
  name: 'aksSupporting'
  params: {
    rgName: rgSpokeName
    vnetName: vnetSpokeName
    subnetName: subnetName
    privateDNSZoneACRName: privateDNSZoneACRName
    privateDNSZoneKVName: privateDNSZoneKVName
    privateDNSZoneSAName: privateDNSZoneSAName
    storageAccountName: storageAccountName
    storageAccountType: storageAccountType
  }
  dependsOn: [networkSpoke]
}

/////////////////
// 06-AKS-Cluster
/////////////////

module aksCluster '../06-AKS-Cluster/main.bicep' = {
  name: 'aksCluster'
  params: {
    rgName: rgSpokeName
    vnetName: vnetSpokeName
    subnetName: aksSubnetName
    aksIdentityName: aksIdentityName
    //location: deployment().location
    enableAutoScaling: enableAutoScaling
    autoScalingProfile: autoScalingProfile
    aksadminaccessprincipalId: aksadminaccessprincipalId
    kubernetesVersion: kubernetesVersion
    keyvaultName: aksSupporting.outputs.keyVaultName
    networkPlugin: networkPlugin
    acrName: aksSupporting.outputs.acrName
    aksClusterName: aksClusterName
  }
}
