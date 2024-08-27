/////////////////
// Global Parameters
/////////////////
targetScope = 'subscription'
param aksadminaccessprincipalId string

/////////////////
// 03-network-Hub
/////////////////

module networkHub '../Bicep/03-Network-Hub/main.bicep' = {
  name: 'hubDeploy'
  params: {
    rgName: 'AKS-LZA-HUB'
    availabilityZones: ['1', '2', '3']
    vnetHubName: 'VNet-HUB'
    hubVNETaddPrefixes: ['10.0.0.0/16']
    azfwName: 'AZFW'
    rtVMSubnetName: 'vm-subnet-rt'
    fwapplicationRuleCollections: [
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
    fwnetworkRuleCollections: [
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
    fwnatRuleCollections: []
  }
}

// /////////////////
// // 04-Network-LZ
// /////////////////

module networkSpoke '../Bicep/04-Network-LZ/main.bicep' = {
  name: 'landingZoneDeploy'
  params: {
    rgName: 'AKS-LZA-SPOKE'
    vnetSpokeName: 'VNet-SPOKE'
    availabilityZones: ['1', '2', '3']
    spokeVNETaddPrefixes: ['10.1.0.0/16']
    rtAKSSubnetName: 'AKS-RT'
    firewallIP: '10.0.1.4'
    vnetHubName: 'VNet-HUB' // Already defined previously
    appGatewayName: 'APPGW'
    vnetHUBRGName: 'AKS-LZA-HUB'
    nsgAKSName: 'AKS-NSG'
    nsgAppGWName: 'APPGW-NSG'
    rtAppGWSubnetName: 'AppGWSubnet-RT'
    dnsServers: []
    appGwyAutoScale: { value: { maxCapacity: 2, minCapacity: 1 } }
    securityRules: []
  }
}

// /////////////////
// // 05-AKS-Supporting
// /////////////////

module aksSupporting '../Bicep/05-AKS-Supporting/main.bicep' = {
  name: 'aksSupporting'
  params: {
    rgName: 'AKS-LZA-SPOKE'
    vnetName: 'VNet-SPOKE'
    subnetName: 'servicespe'
    privateDNSZoneACRName: 'privatelink${environment().suffixes.acrLoginServer}'
    privateDNSZoneKVName: 'privatelink.vaultcore.azure.net'
    privateDNSZoneSAName: 'privatelink.file.${environment().suffixes.storage}'
    acrName: 'eslzacr${uniqueString('acrvws', uniqueString(subscription().id))}'
    keyvaultName: 'eslz-kv-${uniqueString('acrvws', uniqueString(subscription().id))}'
    storageAccountName: 'eslzsa${uniqueString('aks', uniqueString(subscription().id))}'
    storageAccountType: 'Standard_GZRS'
  }
}

// /////////////////
// // 06-AKS-Cluster
// /////////////////

module aksCluster '../Bicep/06-AKS-Cluster/main.bicep' = {
  name: 'aksCluster'
  params: {
    rgName: 'AKS-LZA-SPOKE'
    vnetName: 'VNet-SPOKE'
    subnetName:'AKS'
    appGatewayName:'APPGW'
    aksIdentityName:'aksIdentity'
    location: deployment().location
    enableAutoScaling: true
    autoScalingProfile: {
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
    aksadminaccessprincipalId: aksadminaccessprincipalId
    kubernetesVersion: '1.30'
    keyvaultName: 'eslz-kv-${uniqueString('acrvws', uniqueString(subscription().id))}'
    networkPlugin: 'azure'
  }
}

// /////////////////
// // Testing
// /////////////////

// output firewallName string = azureFirewall.outputs.name
