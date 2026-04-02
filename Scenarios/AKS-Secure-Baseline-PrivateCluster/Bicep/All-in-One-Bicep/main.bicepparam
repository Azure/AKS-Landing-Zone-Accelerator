using './main.bicep'

param deployHub = true
param enablePrivateCluster = true
param rgHubName = 'rg-hub-zt'
param vnetHubName = 'vnet-hub'
param hubVnetAddPrefixes = [
  '10.0.0.0/16'
]
param azfwName = 'afw-hub'
param rtVmSubnetName = 'rt-vm-subnet'
param fwApplicationRuleCollections = [
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
param fwNetworkRuleCollections = [
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
param fwNatRuleCollections = []
param availabilityZones = [
  1
  2
  3
]
param nsgBastionName = 'nsg-bastion'
param rgSpokeName = 'rg-spoke-zt'
param vnetSpokeName = 'vnet-spoke'
param spokeVnetAddPrefixes = [
  '10.1.0.0/16'
]
param spokeSubnetDefaultPrefix = '10.1.0.0/24'
param spokeSubnetAksPrefix = '10.1.1.0/24'
param spokeSubnetAgcPrefix = '10.1.2.0/24'
param spokeSubnetVmPrefix = '10.1.3.0/24'
param spokeSubnetPLinkervicePrefix = '10.1.4.0/24'
param remotePeeringName = 'spoke-hub-peering'
param rtAksSubnetName = 'rt-aks'
param firewallIp = '10.0.1.4'
param agcName = 'alb-controller'
param nsgAksName = 'nsg-aks'
param securityRules = []
param defaultSubnetName = 'default'
param defaultSubnetAddressPrefix = '10.0.0.0/24'
param azureFirewallSubnetName = 'AzureFirewallSubnet'
param azureFirewallSubnetAddressPrefix = '10.0.1.0/26'
param azureFirewallManagementSubnetName = 'AzureFirewallManagementSubnet'
param azureFirewallManagementSubnetAddressPrefix = '10.0.4.0/26'
param azureBastionSubnetName = 'AzureBastionSubnet'
param azureBastionSubnetAddressPrefix = '10.0.2.0/27'
param vmSubnetName = 'vmsubnet'
param vmSubnetAddressPrefix = '10.0.3.0/24'
param linuxVirtualMachineVmSize = 'Standard_DS2_v2'
param jumpboxAdminPassword = ''
param subnetName = 'servicespe'
param storageAccountType = 'Standard_GZRS'
param aksSubnetName = 'AKS'
param aksIdentityName = 'id-aks'
param enableAutoScaling = true
param autoScalingProfile = {
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
param aksAdminAccessPrincipalId = ''
param kubernetesVersion = '1.30'
param networkPlugin = 'azure'
param aksClusterName = 'aks-cluster'
param aksVmSize = 'Standard_D4d_v5'
param aksSkuName = 'Base'

