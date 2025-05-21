/////////////////
// Global Parameters
/////////////////
targetScope = 'subscription'

//////////////////////////////////
//////////////////////////////////
// PARAMETERS
//////////////////////////////////
//////////////////////////////////

param location string
param isMultiRegionDeployment bool = true
param multiRegionSharedRgName string
param isSecondaryRegionDeployment bool = false
param primaryACRName string = ''


/////////////////
// 03-network-Hub
/////////////////
@description('Set this to true if you want to deploy the hub network and its resources')
param deployHub bool = true

@description('Set this to true if you want your aks cluster to be private')
param enablePrivateCluster bool = true

param rgHubName string = 'AKS-LZA-HUB-${toUpper(location)}'
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
param availabilityZones array = [1,2,3]
param nsgBastionName string = 'BASTION-NSG'

/////////////////
// 04-Network-LZ
/////////////////

param rgSpokeName string = 'AKS-LZA-SPOKE-${toUpper(location)}'
param vnetSpokeName string = 'VNet-SPOKE'
//param availabilityZones array = ['1', '2', '3']
param spokeVNETaddPrefixes array = ['10.1.0.0/16']
param spokeSubnetDefaultPrefix string = '10.1.0.0/24'
param spokeSubnetAKSPrefix string = '10.1.1.0/24'
param spokeSubnetAppGWPrefix string = '10.1.2.0/27'
param spokeSubnetVMPrefix string = '10.1.3.0/24'
param spokeSubnetPLinkervicePrefix string = '10.1.4.0/24'
param remotePeeringName string = 'spoke-hub-peering'
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
param linuxVirtualMachineVMSize string = 'Standard_D2ds_v4' //'Standard_DS2_v2'

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
param kubernetesVersion string = '1.30'
param networkPlugin string = 'azure'
param aksClusterName string = 'aksCluster'
param aksVMSize string = 'Standard_D2ds_v4' //'Standard_DS2_v2'

//////////////////////////////////
//////////////////////////////////
// MODULES
//////////////////////////////////
//////////////////////////////////


/////////////////
// 03-network-Hub
/////////////////

module networkHub '../../../AKS-Secure-Baseline-PrivateCluster/Bicep/03-Network-Hub/main.bicep' = if (deployHub) {
  name: 'HUBDEPLOY-${toUpper(location)}'
  scope: subscription()
  params: {
    rgName: rgHubName
    availabilityZones: availabilityZones
    spokeSubnetAKSPrefix: spokeSubnetAKSPrefix
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
    nsgBastionName:nsgBastionName
  }
}

/////////////////
// 04-Network-LZ
/////////////////

module networkSpoke '../../../AKS-Secure-Baseline-PrivateCluster/Bicep/04-Network-LZ/main.bicep' = {
  name: 'LZASPOKEDEPLOY-${toUpper(location)}'
  scope: subscription()
  params: {
    rgName: rgSpokeName
    enablePrivateCluster: enablePrivateCluster
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
    spokeSubnetDefaultPrefix: spokeSubnetDefaultPrefix
    spokeSubnetAKSPrefix: spokeSubnetAKSPrefix
    spokeSubnetAppGWPrefix: spokeSubnetAppGWPrefix
    spokeSubnetVMPrefix:spokeSubnetVMPrefix
    spokeSubnetPLinkervicePrefix: spokeSubnetPLinkervicePrefix
    remotePeeringName: remotePeeringName
    vmSize: linuxVirtualMachineVMSize

  }
  dependsOn: deployHub ? [networkHub] : []
}

/////////////////
// 05-AKS-Supporting
/////////////////

module aksSupporting '../../../AKS-Secure-Baseline-PrivateCluster/Bicep/05-AKS-Supporting/main.bicep' = {
  name: 'AKSSUPPORTING-${toUpper(location)}'
  scope: subscription()
  params: {
    rgName: rgSpokeName
    vnetName: vnetSpokeName
    subnetName: subnetName
    privateDNSZoneACRName: privateDNSZoneACRName
    privateDNSZoneKVName: privateDNSZoneKVName
    privateDNSZoneSAName: privateDNSZoneSAName
    storageAccountName: storageAccountName
    storageAccountType: storageAccountType
    multiRegionSharedRgName: multiRegionSharedRgName
    isSecondaryRegionDeployment: isSecondaryRegionDeployment
    existingAcrName: primaryACRName
  }
  dependsOn: [networkSpoke]
}

/////////////////
// 06-AKS-Cluster
/////////////////

module aksCluster '../../../AKS-Secure-Baseline-PrivateCluster/Bicep/06-AKS-Cluster/main.bicep' = {
  name: 'AksLZACluster-${toUpper(location)}'
  scope: subscription()
  params: {
    rgName: rgSpokeName
    enablePrivateCluster: enablePrivateCluster
    vnetName: vnetSpokeName
    subnetName: aksSubnetName
    aksIdentityName: aksIdentityName
    location: location
    enableAutoScaling: enableAutoScaling
    autoScalingProfile: autoScalingProfile
    kubernetesVersion: kubernetesVersion
    keyvaultName: aksSupporting.outputs.keyVaultName
    networkPlugin: networkPlugin
    acrName: aksSupporting.outputs.acrName
    aksClusterName: aksClusterName
    vmSize: aksVMSize
    isMultiRegionDeployment: isMultiRegionDeployment
  }
}


output acrName string = aksSupporting.outputs.acrName
output keyVaultName string = aksSupporting.outputs.keyVaultName
output aksClusterName string = aksClusterName
output rgSpokeName string = rgSpokeName
output vmSystemAssignedMIPrincipalId string = networkSpoke.outputs.vmSystemAssignedMIPrincipalId
