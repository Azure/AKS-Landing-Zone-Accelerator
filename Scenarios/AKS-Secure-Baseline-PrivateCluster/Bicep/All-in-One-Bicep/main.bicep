/////////////////
// Global Parameters
/////////////////
targetScope = 'subscription'

//////////////////////////////////
//////////////////////////////////
// PARAMETERS
//////////////////////////////////
//////////////////////////////////

/////////////////
// 03-network-Hub
/////////////////
@description('Set this to true if you want to deploy the hub network and its resources')
param deployHub bool = true

@description('Set this to true if you want your aks cluster to be private')
param enablePrivateCluster bool = true

param rgHubName string = 'rg-hub'
param vnetHubName string = 'vnet-hub'
param hubVnetAddPrefixes array = ['10.0.0.0/16']
param azfwName string = 'afw-hub'
param rtVmSubnetName string = 'rt-vm-subnet'
param fwApplicationRuleCollections array = [
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
param fwNetworkRuleCollections array = [
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
param fwNatRuleCollections array = []
param availabilityZones array = [1, 2, 3]
param nsgBastionName string = 'nsg-bastion'
/////////////////
// 04-Network-LZ
/////////////////

param rgSpokeName string = 'rg-spoke'
param vnetSpokeName string = 'vnet-spoke'
param spokeVnetAddPrefixes array = ['10.1.0.0/16']
param spokeSubnetDefaultPrefix string = '10.1.0.0/24'
param spokeSubnetAksPrefix string = '10.1.1.0/24'
param spokeSubnetAgcPrefix string = '10.1.2.0/24'
param spokeSubnetVmPrefix string = '10.1.3.0/24'
param spokeSubnetPLinkervicePrefix string = '10.1.4.0/24'
param remotePeeringName string = 'spoke-hub-peering'
param rtAksSubnetName string = 'rt-aks'
param firewallIp string = '10.0.1.4'
param agcName string = 'alb-controller'
param nsgAksName string = 'nsg-aks'
param securityRules array = []
param defaultSubnetName string = 'default'
param defaultSubnetAddressPrefix string = '10.0.0.0/24'
param azureFirewallSubnetName string = 'AzureFirewallSubnet'
param azureFirewallSubnetAddressPrefix string = '10.0.1.0/26'
param azureFirewallManagementSubnetName string = 'AzureFirewallManagementSubnet'
param azureFirewallManagementSubnetAddressPrefix string = '10.0.4.0/26'
param azureBastionSubnetName string = 'AzureBastionSubnet'
param azureBastionSubnetAddressPrefix string = '10.0.2.0/27'
param vmSubnetName string = 'vmsubnet'
param vmSubnetAddressPrefix string = '10.0.3.0/24'
param linuxVirtualMachineVmSize string = 'Standard_DS2_v2'

@secure()
@description('The admin password for the jumpbox VM in the spoke network.')
param jumpboxAdminPassword string

/////////////////
// 05-AKS-Supporting
/////////////////


param subnetName string = 'servicespe'
param privateDnsZoneAcrName string = 'privatelink${environment().suffixes.acrLoginServer}'
param privateDnsZoneKvName string = 'privatelink.vaultcore.azure.net'
param privateDnsZoneSaName string = 'privatelink.file.${environment().suffixes.storage}'
param storageAccountName string = 'st${uniqueString('aks', uniqueString(subscription().id, utcNow()))}'
param storageAccountType string = 'Standard_GZRS'

/////////////////
// 06-AKS-Cluster
/////////////////


param aksSubnetName string = 'AKS'
param aksIdentityName string = 'id-aks'
param enableAutoScaling bool = true
param autoScalingProfile object = {
  balanceSimilarNodeGroups: false
  expander: 'random'
  maxEmptyBulkDelete: 10
  maxGracefulTerminationSec: 600
  maxNodeProvisionTime: '15m'
  maxTotalUnreadyPercentage: 45
  newPodScaleUpDelay: '0s'
  okTotalUnreadyCount: 3
  scaleDownDelayAfterAdd: '10m'
  scaleDownDelayAfterDelete: '10s'
  scaleDownDelayAfterFailure: '3m'
  scaleDownUnneededTime: '10m'
  scaleDownUnreadyTime: '20m'
  scaleDownUtilizationThreshold: '0.5'
  scanInterval: '10s'
  skipNodesWithLocalStorage: false
  skipNodesWithSystemPods: true
}
param aksAdminAccessPrincipalId string
param kubernetesVersion string = '1.30'
param networkPlugin string = 'azure'
param aksClusterName string = 'aks-cluster'
param aksVmSize string = 'Standard_D4d_v5'

@description('Optional. The AKS cluster SKU name. Set to "Automatic" for AKS Automatic mode, or "Base" for standard mode.')
@allowed([
  'Base'
  'Automatic'
])
param aksSkuName string = 'Base'

//////////////////////////////////
//////////////////////////////////
// MODULES
//////////////////////////////////
//////////////////////////////////


/////////////////
// 03-network-Hub
/////////////////

module networkHub '../03-Network-Hub/main.bicep' = if (deployHub) {
  name: 'hubDeploy'
  params: {
    rgName: rgHubName
    availabilityZones: availabilityZones
    spokeSubnetAksPrefix: spokeSubnetAksPrefix
    vnetHubName: vnetHubName
    azfwName: azfwName
    rtVmSubnetName: rtVmSubnetName
    fwApplicationRuleCollections: fwApplicationRuleCollections
    fwNetworkRuleCollections: fwNetworkRuleCollections
    fwNatRuleCollections: fwNatRuleCollections
    hubVnetAddPrefixes: hubVnetAddPrefixes
    defaultSubnetName: defaultSubnetName
    defaultSubnetAddressPrefix: defaultSubnetAddressPrefix
    azureFirewallSubnetName: azureFirewallSubnetName
    azureFirewallSubnetAddressPrefix: azureFirewallSubnetAddressPrefix
    azureFirewallManagementSubnetName: azureFirewallManagementSubnetName
    azureFirewallManagementSubnetAddressPrefix: azureFirewallManagementSubnetAddressPrefix
    azureBastionSubnetName: azureBastionSubnetName
    azureBastionSubnetAddressPrefix: azureBastionSubnetAddressPrefix
    vmSubnetName: vmSubnetName
    vmSubnetAddressPrefix: vmSubnetAddressPrefix
    nsgBastionName: nsgBastionName
  }
}

/////////////////
// 04-Network-LZ
/////////////////

module networkSpoke '../04-Network-LZ/main.bicep' = {
  name: 'lzSpokeDeploy'
  params: {
    rgName: rgSpokeName
    enablePrivateCluster: enablePrivateCluster
    vnetSpokeName: vnetSpokeName
    spokeVnetAddPrefixes: spokeVnetAddPrefixes
    rtAksSubnetName: rtAksSubnetName
    firewallIp: firewallIp
    vnetHubName: vnetHubName
    agcName: agcName
    vnetHubRgName: rgHubName
    nsgAksName: nsgAksName
    securityRules: securityRules
    spokeSubnetDefaultPrefix: spokeSubnetDefaultPrefix
    spokeSubnetAksPrefix: spokeSubnetAksPrefix
    spokeSubnetAgcPrefix: spokeSubnetAgcPrefix
    spokeSubnetVmPrefix: spokeSubnetVmPrefix
    spokeSubnetPLinkervicePrefix: spokeSubnetPLinkervicePrefix
    remotePeeringName: remotePeeringName
    vmSize: linuxVirtualMachineVmSize
    jumpboxAdminPassword: jumpboxAdminPassword
  }
  dependsOn: deployHub ? [networkHub] : []
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
    privateDnsZoneAcrName: privateDnsZoneAcrName
    privateDnsZoneKvName: privateDnsZoneKvName
    privateDnsZoneSaName: privateDnsZoneSaName
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
    enablePrivateCluster: enablePrivateCluster
    vnetName: vnetSpokeName
    subnetName: aksSubnetName
    aksIdentityName: aksIdentityName
    enableAutoScaling: enableAutoScaling
    autoScalingProfile: autoScalingProfile
    aksAdminAccessPrincipalId: aksAdminAccessPrincipalId
    kubernetesVersion: kubernetesVersion
    keyVaultName: aksSupporting.outputs.keyVaultName
    networkPlugin: networkPlugin
    acrName: aksSupporting.outputs.acrName
    aksClusterName: aksClusterName
    vmSize: aksVmSize
    aksSkuName: aksSkuName
    enableKmsEncryption: true
    kmsKeyUri: aksSupporting.outputs.kmsKeyUri
  }
}
