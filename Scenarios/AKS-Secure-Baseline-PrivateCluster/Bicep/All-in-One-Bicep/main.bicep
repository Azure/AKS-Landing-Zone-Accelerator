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

@description('The name of the resource group for the hub network.')
param rgHubName string = 'rg-hub'

@description('The name of the hub virtual network.')
param vnetHubName string = 'vnet-hub'

@description('The address prefixes for the hub virtual network.')
param hubVnetAddPrefixes array = ['10.0.0.0/16']

@description('The name of the Azure Firewall.')
param azfwName string = 'afw-hub'

@description('The name of the route table for the VM subnet.')
param rtVmSubnetName string = 'rt-vm-subnet'

@description('Application rule collections for Azure Firewall.')
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
@description('Network rule collections for Azure Firewall.')
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
@description('NAT rule collections for Azure Firewall.')
param fwNatRuleCollections array = []

@description('The availability zones to deploy resources into.')
param availabilityZones array = [1, 2, 3]

@description('The name of the NSG for the Bastion subnet.')
param nsgBastionName string = 'nsg-bastion'
/////////////////
// 04-Network-LZ
/////////////////

@description('The name of the resource group for the spoke network.')
param rgSpokeName string = 'rg-spoke'

@description('The name of the spoke virtual network.')
param vnetSpokeName string = 'vnet-spoke'

@description('The address prefixes for the spoke virtual network.')
param spokeVnetAddPrefixes array = ['10.1.0.0/16']

@description('The address prefix for the default subnet in the spoke VNet.')
param spokeSubnetDefaultPrefix string = '10.1.0.0/24'

@description('The address prefix for the AKS subnet.')
param spokeSubnetAksPrefix string = '10.1.1.0/24'

@description('The address prefix for the AGC delegated subnet.')
param spokeSubnetAgcPrefix string = '10.1.2.0/24'

@description('The address prefix for the VM subnet in the spoke VNet.')
param spokeSubnetVmPrefix string = '10.1.3.0/24'

@description('The address prefix for the private link services subnet.')
param spokeSubnetPLinkervicePrefix string = '10.1.4.0/24'

@description('The name of the peering from spoke to hub VNet.')
param remotePeeringName string = 'spoke-hub-peering'

@description('The name of the route table for the AKS subnet.')
param rtAksSubnetName string = 'rt-aks'

@description('The private IP address of the Azure Firewall in the hub network.')
param firewallIp string = '10.0.1.4'

@description('The name of the Application Gateway for Containers traffic controller.')
param agcName string = 'alb-controller'

@description('The name of the NSG for the AKS subnet.')
param nsgAksName string = 'nsg-aks'

@description('Additional security rules for the AKS NSG.')
param securityRules array = []

@description('The name of the default subnet in the hub VNet.')
param defaultSubnetName string = 'default'

@description('The address prefix for the default subnet.')
param defaultSubnetAddressPrefix string = '10.0.0.0/24'

@description('The name of the Azure Firewall subnet.')
param azureFirewallSubnetName string = 'AzureFirewallSubnet'

@description('The address prefix for the Azure Firewall subnet.')
param azureFirewallSubnetAddressPrefix string = '10.0.1.0/26'

@description('The name of the Azure Firewall management subnet.')
param azureFirewallManagementSubnetName string = 'AzureFirewallManagementSubnet'

@description('The address prefix for the Azure Firewall management subnet.')
param azureFirewallManagementSubnetAddressPrefix string = '10.0.4.0/26'

@description('The name of the Azure Bastion subnet.')
param azureBastionSubnetName string = 'AzureBastionSubnet'

@description('The address prefix for the Azure Bastion subnet.')
param azureBastionSubnetAddressPrefix string = '10.0.2.0/27'

@description('The name of the VM subnet in the hub VNet.')
param vmSubnetName string = 'vmsubnet'

@description('The address prefix for the VM subnet.')
param vmSubnetAddressPrefix string = '10.0.3.0/24'

@description('The VM size for the jumpbox virtual machine.')
param linuxVirtualMachineVmSize string = 'Standard_DS2_v2'

@secure()
@description('The admin password for the jumpbox VM in the spoke network.')
param jumpboxAdminPassword string

/////////////////
// 05-AKS-Supporting
/////////////////


@description('The name of the subnet for private endpoints.')
param subnetName string = 'servicespe'

@description('The name of the storage account. Override to use a custom name.')
param storageAccountName string = 'st${aksClusterName}${uniqueString(aksClusterName, subscription().id)}'

@description('The storage account SKU type.')
param storageAccountType string = 'Standard_GZRS'

/////////////////
// 06-AKS-Cluster
/////////////////


@description('The name of the AKS subnet.')
param aksSubnetName string = 'AKS'

@description('The name of the user-assigned managed identity for AKS.')
param aksIdentityName string = 'id-aks'

@description('Enable cluster autoscaling.')
param enableAutoScaling bool = true

@description('Cluster autoscaler profile settings.')
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
@description('The object ID of the Entra ID group for AKS cluster admins.')
param aksAdminAccessPrincipalId string

@description('The Kubernetes version for the AKS cluster.')
param kubernetesVersion string = '1.30'

@description('The network plugin for the AKS cluster.')
param networkPlugin string = 'azure'

@description('The name of the AKS cluster.')
param aksClusterName string = 'aks-cluster'

@description('The VM size for AKS node pools.')
param aksVmSize string = 'Standard_D4d_v5'

@description('Optional. The AKS cluster SKU name. Set to "Automatic" for AKS Automatic mode, or "Base" for standard mode.')
@allowed([
  'Base'
  'Automatic'
])
param aksSkuName string = 'Base'

//////////////////////////////////
//////////////////////////////////
// VARIABLES
//////////////////////////////////
//////////////////////////////////

// Private DNS zone names are deterministic — derived from the Azure environment
var privateDnsZoneAcrName = 'privatelink${environment().suffixes.acrLoginServer}'
var privateDnsZoneKvName = 'privatelink.vaultcore.azure.net'
var privateDnsZoneSaName = 'privatelink.file.${environment().suffixes.storage}'

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
