/////////////////
// Global Parameters
/////////////////
targetScope = 'subscription'
//param location string = deployment().location
//param availabilityZones array = ['1','2','3']

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

// module rgHub 'br/public:avm/res/resources/resource-group:0.2.3' = {
//   name: rgHubName
//   params: {
//     name: rgHubName
//     location: location
//     enableTelemetry: true
//   }
// }

// module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
//   scope: resourceGroup(rgHub.name)
//   name: vnetHubName
//   params: {
//     addressPrefixes: hubVnetAddPrefixes
//     name: vnetHubName
//     location: location
//     subnets: [
//       {
//         name: 'default'
//         addressPrefix: '10.0.0.0/24'
//       }
//       {
//         name: 'AzureFirewallSubnet'
//         addressPrefix: '10.0.1.0/26'
//       }
//       {
//         name: 'AzureFirewallManagementSubnet'
//         addressPrefix: '10.0.4.0/26'
//       }
//       {
//         name: 'AzureBastionSubnet'
//         addressPrefix: '10.0.2.0/27'
//       }
//       {
//         name: 'vmsubnet'
//         addressPrefix: '10.0.3.0/24'
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module publicIpFW 'br/public:avm/res/network/public-ip-address:0.3.1' = {
//   scope: resourceGroup(rgHub.name)
//   name: 'AZFW-PIP'
//   params: {
//     name: 'AZFW-PIP'
//     location: location
//     zones: availabilityZones
//     publicIPAllocationMethod: 'Static'
//     skuName: 'Standard'
//     skuTier: 'Regional'
//     enableTelemetry: true
//   }
// }

// module publicIpFWMgmt 'br/public:avm/res/network/public-ip-address:0.3.1' = {
//   scope: resourceGroup(rgHub.name)
//   name: 'AZFW-Management-PIP'
//   params: {
//     name: 'AZFW-Management-PIP'
//     location: location
//     zones: availabilityZones
//     publicIPAllocationMethod: 'Static'
//     skuName: 'Standard'
//     skuTier: 'Regional'
//     enableTelemetry: true
//   }
// }

// module publicipbastion 'br/public:avm/res/network/public-ip-address:0.3.1' = {
//   scope: resourceGroup(rgHub.name)
//   name: 'publicipbastion'
//   params: {
//     name: 'publicipbastion'
//     location: location
//     zones: availabilityZones
//     publicIPAllocationMethod: 'Static'
//     skuName: 'Standard'
//     skuTier: 'Regional'
//     enableTelemetry: true
//   }
// }

// module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
//   scope: resourceGroup(rgHub.name)
//   name: 'bastion'
//   params: {
//     name: 'bastion'
//     vNetId: virtualNetwork.outputs.resourceId
//     bastionSubnetPublicIpResourceId: publicipbastion.outputs.resourceId
//     location: location
//     enableTelemetry: true
//   }
// }

// module routeTable 'br/public:avm/res/network/route-table:0.2.2' = {
//   scope: resourceGroup(rgHub.name)
//   name: rtVMSubnetName
//   params: {
//     name: rtVMSubnetName
//     location: location
//     routes: [
//       {
//         name: 'vm-to-internet'
//         properties: {
//           addressPrefix: '0.0.0.0/0'
//           nextHopIpAddress: azureFirewall.outputs.privateIp
//           nextHopType: 'VirtualAppliance'
//         }
//       }
//     ]
//   }
// }

// module azureFirewall 'br/public:avm/res/network/azure-firewall:0.1.1' = {
//   scope: resourceGroup(rgHub.name)
//   name: azfwName
//   params: {
//     name: azfwName
//     location: location
//     virtualNetworkResourceId: virtualNetwork.outputs.resourceId
//     zones: availabilityZones
//     publicIPResourceID: publicIpFW.outputs.resourceId
//     managementIPResourceID: publicIpFWMgmt.outputs.resourceId
//     applicationRuleCollections: fwapplicationRuleCollections
//     natRuleCollections: fwnatRuleCollections
//     networkRuleCollections: fwnetworkRuleCollections
//   }
// }

// /////////////////
// // 04-Network-LZ
// /////////////////

// param rgSpokeName string = 'AKS-LZA-SPOKE'
// param vnetSpokeName string = 'VNet-SPOKE'
// param spokeVNETaddPrefixes array = ['10.1.0.0/16']
// param rtAKSSubnetName string = 'AKS-RT'
// param firewallIP string = '10.0.1.4'
// //param vnetHubName string = 'VNet-HUB' // Already defined previously
// //param appGatewayName string = 'APPGW'
// param vnetHUBRGName string = 'AKS-LZA-HUB'
// param nsgAKSName string = 'AKS-NSG'
// param nsgAppGWName string = 'APPGW-NSG'
// param rtAppGWSubnetName string = 'AppGWSubnet-RT'
// param appGwyAutoScale object = {value: {maxCapacity: 2, minCapacity: 1}}
// param securityRules array = []

// var privateDNSZoneAKSSuffixes = {
//   AzureCloud: '.azmk8s.io'
//   AzureUSGovernment: '.cx.aks.containerservice.azure.us'
//   AzureChinaCloud: '.cx.prod.service.azk8s.cn'
//   AzureGermanCloud: '' //TODO: what is the correct value here?
// }

// resource vnethub 'Microsoft.Network/virtualNetworks@2021-02-01' existing = {
//   scope: resourceGroup(vnetHUBRGName)
//   name: vnetHubName
// }

// module rgSpoke 'br/public:avm/res/resources/resource-group:0.2.3' = {
//   name: rgSpokeName
//   params: {
//     name: rgSpokeName
//     location: location
//     enableTelemetry: true
//   }
// }

// module vnetspoke 'br/public:avm/res/network/virtual-network:0.1.1' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: vnetSpokeName
//   params: {
//     addressPrefixes: spokeVNETaddPrefixes
//     name: vnetSpokeName
//     location: location
//     subnets: [
//       {
//         name: 'default'
//         addressPrefix: '10.1.0.0/24'
//       }
//       {
//         name: 'AKS'
//         addressPrefix: '10.1.1.0/24'
//         routeTableResourceId: routeTable.outputs.resourceId
//       }
//       {
//         name: 'AppGWSubnet'
//         addressPrefix: '10.1.2.0/27'
//       }
//       {
//         name: 'vmsubnet'
//         addressPrefix: '10.1.3.0/24'
//       }
//       {
//         name: 'servicespe'
//         addressPrefix: '10.1.4.0/24'
//       }
//     ]
//     enableTelemetry: true
//     // dnsServers: dnsServers
//     peerings: [
//       {
//         allowForwardedTraffic: true
//         allowGatewayTransit: false
//         allowVirtualNetworkAccess: true
//         remotePeeringAllowForwardedTraffic: true
//         remotePeeringAllowVirtualNetworkAccess: true
//         remotePeeringEnabled: true
//         remotePeeringName: 'spoke-hub-peering'
//         remoteVirtualNetworkId: vnethub.id
//         useRemoteGateways: false
//       }
//     ]
//   }
//   dependsOn: [
//     routeTable
//     appGwyRouteTable
//   ]
// }

// module networkSecurityGroupAKS 'br/public:avm/res/network/network-security-group:0.1.3' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: nsgAKSName
//   params: {
//     name: nsgAKSName
//     location: location
//     securityRules: securityRules
//     enableTelemetry: true
//   }
// }

// module networkSecurityGroupAppGwy 'br/public:avm/res/network/network-security-group:0.1.3' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: nsgAppGWName
//   params: {
//     name: nsgAppGWName
//     location: location
//     securityRules: [
//       {
//         name: 'Allow443InBound'
//         properties: {
//           access: 'Allow'
//           destinationAddressPrefix: '*'
//           destinationPortRange: '443'
//           direction: 'Inbound'
//           priority: 102
//           protocol: 'Tcp'
//           sourceAddressPrefix: '*'
//           sourcePortRange: '*'
//         }
//       }
//       {
//         name: 'AllowControlPlaneV1SKU'
//         properties: {
//           access: 'Allow'
//           destinationAddressPrefix: '*'
//           destinationPortRange: '65503-65534'
//           direction: 'Inbound'
//           priority: 110
//           protocol: '*'
//           sourceAddressPrefix: 'GatewayManager'
//           sourcePortRange: '*'
//         }
//       }
//       {
//         name: 'AllowControlPlaneV2SKU'
//         properties: {
//           access: 'Allow'
//           destinationAddressPrefix: '*'
//           destinationPortRange: '65200-65535'
//           direction: 'Inbound'
//           priority: 111
//           protocol: '*'
//           sourceAddressPrefix: 'GatewayManager'
//           sourcePortRange: '*'
//         }
//       }
//       {
//         name: 'AllowHealthProbes'
//         properties: {
//           access: 'Allow'
//           destinationAddressPrefix: '*'
//           destinationPortRange: '*'
//           direction: 'Inbound'
//           priority: 120
//           protocol: '*'
//           sourceAddressPrefix: 'AzureLoadBalancer'
//           sourcePortRange: '*'
//         }
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module routeTableSpoke 'br/public:avm/res/network/route-table:0.2.2' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: rtAKSSubnetName
//   params: {
//     name: rtAKSSubnetName
//     location: location
//     routes: [
//       {
//         name: 'vm-to-internet'
//         properties: {
//           addressPrefix: '0.0.0.0/0'
//           nextHopIpAddress: firewallIP
//           nextHopType: 'VirtualAppliance'
//         }
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module appGwyRouteTable 'br/public:avm/res/network/route-table:0.2.2' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: rtAppGWSubnetName
//   params: {
//     name: rtAppGWSubnetName
//     location: location
//     routes: [
//       {
//         name: 'vm-to-internet'
//         properties: {
//           addressPrefix: '0.0.0.0/0'
//           nextHopIpAddress: firewallIP
//           nextHopType: 'VirtualAppliance'
//         }
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module privateDnsZoneACR 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'privatednsACRZone'
//   params: {
//     name: 'privatelink${environment().suffixes.acrLoginServer}'
//     location: 'global'
//     virtualNetworkLinks: [
//       {
//         virtualNetworkResourceId: vnethub.id
//       }
//       {
//         virtualNetworkResourceId: vnetspoke.outputs.resourceId
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module privateDnsZoneKV 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'privatednsKVZone'
//   params: {
//     name: 'privatelink.vaultcore.azure.net'
//     location: 'global'
//     virtualNetworkLinks: [
//       {
//         virtualNetworkResourceId: vnethub.id
//       }
//       {
//         virtualNetworkResourceId: vnetspoke.outputs.resourceId
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module privateDnsZoneSA 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'privatednsSAZone'
//   params: {
//     name: 'privatelink.file.${environment().suffixes.storage}'
//     location: 'global'
//     virtualNetworkLinks: [
//       {
//         virtualNetworkResourceId: vnethub.id
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module privateDnsZoneAKS 'br/public:avm/res/network/private-dns-zone:0.2.4' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'privatednsAKSZone'
//   params: {
//     name: 'privatelink.${toLower(location)}${privateDNSZoneAKSSuffixes[environment().name]}'
//     location: 'global'
//     virtualNetworkLinks: [
//       {
//         virtualNetworkResourceId: vnethub.id
//       }
//     ]
//     enableTelemetry: true
//   }
// }

// module publicIpAppGwy 'br/public:avm/res/network/public-ip-address:0.3.1' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'APPGW-PIP'
//   params: {
//     name: 'APPGW-PIP'
//     location: location
//     zones: availabilityZones
//     publicIPAllocationMethod: 'Static'
//     skuName: 'Standard'
//     skuTier: 'Regional'
//     enableTelemetry: true
//   }
// }

// // module appgw 'appgw.bicep' = {
// //   scope: resourceGroup(rg.name)
// //   name: 'appgw'
// //   params: {
// //     appGwyAutoScale: appGwyAutoScale
// //     availabilityZones: availabilityZones
// //     location: location
// //     appgwname: appGatewayName
// //     appgwpip: publicIpAppGwy.outputs.resourceId
// //     subnetid: vnetspoke.outputs.subnetResourceIds[2]
// //     // rgName: rgName
// //   }
// // }

// module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.2.1' = {
//   scope: resourceGroup(rgIdentity.name)
//   name: 'aksIdentity'
//   params: {
//     name: 'aksIdentity'
//     location: location
//   }
// }

// module virtualMachine 'br/public:avm/res/compute/virtual-machine:0.5.0' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'virtualMachineDeployment'
//   params: {
//     // Required parameters
//     adminUsername: 'azureuser'
//     imageReference: {
//       offer: '0001-com-ubuntu-server-jammy'
//       publisher: 'Canonical'
//       sku: '22_04-lts-gen2'
//       version: 'latest'
//     }
//     name: 'jumpbox'
//     nicConfigurations: [
//       {
//         ipConfigurations: [
//           {
//             name: 'ipconfig01'
//             pipConfiguration: {
//               name: 'pip-01'
//             }
//             subnetResourceId: vnetspoke.outputs.subnetResourceIds[3]
//           }
//         ]
//         nicSuffix: '-nic-01'
//       }
//     ]
//     osDisk: {
//       caching: 'ReadWrite'
//       diskSizeGB: 128
//       managedDisk: {
//         storageAccountType: 'Premium_LRS'
//       }
//     }
//     osType: 'Linux'
//     vmSize: 'Standard_DS2_v2'
//     zone: 0
//     // Non-required parameters
//     disablePasswordAuthentication: false
//     adminPassword: 'Password123'
//     location: location
//   }
// }

// /////////////////
// // 05-AKS-Supporting
// /////////////////
// //param rgName string // No need to create this as all supporting resources go into the existing spoke RG.
// //param vnetName string
// param subnetName string = 'servicespe'
// param privateDNSZoneACRName string = 'privatelink${environment().suffixes.acrLoginServer}'
// param privateDNSZoneKVName string = 'privatelink.vaultcore.azure.net'
// param privateDNSZoneSAName string = 'privatelink.file.${environment().suffixes.storage}'
// param acrName string = 'eslzacr${uniqueString('acrvws', uniqueString(subscription().id))}'
// param keyvaultLandingZoneName string = 'eslz-kv-${uniqueString('acrvws', uniqueString(subscription().id))}'
// param storageAccountName string = 'eslzsa${uniqueString('aks', uniqueString(subscription().id))}'
// param storageAccountType string = 'Standard_GZRS'

// resource servicesSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: '${vnetSpokeName}/${subnetName}'
// }

// resource privateDNSZoneSA 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: privateDNSZoneSAName
// }

// resource privateDNSZoneKV 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: privateDNSZoneKVName
// }

// resource privateDNSZoneACR 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: privateDNSZoneACRName
// }

// // // No need to create this as all supporting resources go into the existing spoke RG.
// // module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
// //   name: rgSpokeName
// //   params: {
// //     name: rgSpokeName
// //     location: location
// //     enableTelemetry: true
// //   }
// // }

// module registry 'br/public:avm/res/container-registry/registry:0.1.1' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: acrName
//   params: {
//     name: acrName
//     location: location
//     acrAdminUserEnabled: true
//     publicNetworkAccess: 'Disabled'
//     acrSku: 'Premium'
//     privateEndpoints: [
//       {
//         privateDnsZoneResourceIds: [
//           privateDNSZoneACR.id
//         ]
//         subnetResourceId: servicesSubnet.id
//       }
//     ]
//   }
//   dependsOn: [
//     vnetspoke
//   ]
// }

// module vault 'br/public:avm/res/key-vault/vault:0.4.0' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: keyvaultName
//   params: {
//     name: keyvaultName
//     enablePurgeProtection: true
//     location: location
//     sku: 'standard'
//     enableVaultForDiskEncryption: true
//     softDeleteRetentionInDays: 7
//     networkAcls: {
//       bypass: 'AzureServices'
//       defaultAction: 'Deny'
//     }
//     privateEndpoints: [
//       {
//         privateDnsZoneResourceIds: [
//           privateDNSZoneKV.id
//         ]
//         subnetResourceId: servicesSubnet.id
//       }
//     ]
//   }
//   dependsOn: [
//     vnetspoke
//   ]
// }

// module storageAccount 'br/public:avm/res/storage/storage-account:0.8.2' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: storageAccountName
//   params: {
//     name: storageAccountName
//     allowBlobPublicAccess: false
//     location: location
//     skuName: storageAccountType
//     kind: 'StorageV2'
//     privateEndpoints: [
//       {
//         privateDnsZoneResourceIds: [
//           privateDNSZoneSA.id
//         ]
//         service: 'file'
//         subnetResourceId: servicesSubnet.id
//       }
//     ]
//   }
//   dependsOn: [
//     vnetspoke
//   ]
// }

// /////////////////
// // 06-AKS-Cluster
// /////////////////

// //param rgName string
// // param vnetName string
// param aksSubnetName string = 'AKS'
// param appGatewayName string = 'APPGW'
// param aksIdentityName string = 'aksIdentity'
// //param location string = deployment().location
// param enableAutoScaling bool = true
// param autoScalingProfile object = {
//   balanceSimilarNodeGroups: 'false'
//   expander: 'random'
//   maxEmptyBulkDelete: '10'
//   maxGracefulTerminationSec: '600'
//   maxNodeProvisionTime: '15m'
//   maxTotalUnreadyPercentage: '45'
//   newPodScaleUpDelay: '0s'
//   okTotalUnreadyCount: '3'
//   scaleDownDelayAfterAdd: '10m'
//   scaleDownDelayAfterDelete: '10s'
//   scaleDownDelayAfterFailure: '3m'
//   scaleDownUnneededTime: '10m'
//   scaleDownUnreadyTime: '20m'
//   scaleDownUtilizationThreshold: '0.5'
//   scanInterval: '10s'
//   skipNodesWithLocalStorage: 'false'
//   skipNodesWithSystemPods: 'true'
// }
// param aksadminaccessprincipalId string // This value will need to be entered at deployment time via the Portal - it is the GUID of the AKS Admin security group.
// param kubernetesVersion string = '1.30'
// param keyvaultName string = 'eslz-kv-${uniqueString('acrvws', uniqueString(subscription().id))}'
// param acrLandingZoneName string = 'eslzacr${uniqueString('acrvws', uniqueString(subscription().id))}'
// param rgIdentityName string = 'AKS-LZA-IDENTITY'

// @allowed([
//   'azure'
//   'kubenet'
// ])
// param networkPlugin string = 'azure'

// // var privateDNSZoneAKSSuffixes = {
// //   AzureCloud: '.azmk8s.io'
// //   AzureUSGovernment: '.cx.aks.containerservice.azure.us'
// //   AzureChinaCloud: '.cx.prod.service.azk8s.cn'
// //   AzureGermanCloud: '' //TODO: what is the correct value here?
// // }

// var privateDNSZoneAKSName = 'privatelink.${toLower(location)}${privateDNSZoneAKSSuffixes[environment().name]}'

// // resource aksIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
// //   scope: resourceGroup(rgSpokeName)
// //   name: aksIdentityName
// // }

// resource pvtdnsAKSZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
//   name: privateDNSZoneAKSName
//   scope: resourceGroup(rgSpoke.name)
// }

// resource aksSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: '${vnetSpokeName}/${subnetName}'
// }

// resource appGateway 'Microsoft.Network/applicationGateways@2021-02-01' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: appGatewayName
// }

// resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: keyvaultName
// }

// resource ACR 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
//   scope: resourceGroup(rgSpoke.name)
//   name: acrName
// }

// // module rgSpoke 'br/public:avm/res/resources/resource-group:0.2.3' = {
// //   name: rgSpokeName
// //   params: {
// //     name: rgSpokeName
// //     location: location
// //     enableTelemetry: true
// //     roleAssignments: [
// //       {
// //         principalId: aksIdentity.properties.principalId
// //         roleDefinitionIdOrName: 'f1a07417-d97a-45cb-824c-7a7467783830'
// //       }
// //       {
// //         principalId: aksIdentity.properties.principalId
// //         roleDefinitionIdOrName: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
// //       }
// //     ]
// //   }
// // }

// module rgIdentity 'br/public:avm/res/resources/resource-group:0.2.3' = {
//   name: rgIdentityName
//   params: {
//     name: rgIdentityName
//     location: location
//     enableTelemetry: true
//   }
// }

// module workspace 'br/public:avm/res/operational-insights/workspace:0.3.4' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'akslaworkspace'
//   params: {
//     name: 'akslaworkspace'
//     location: location
//   }
// }

// module managedCluster 'br/public:avm/res/container-service/managed-cluster:0.1.2' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'aksCluster'
//   params: {
//     name: 'aksCluster'
//     primaryAgentPoolProfile: [
//       {
//         availabilityZones: [
//           '3'
//         ]
//         count: 3
//         enableAutoScaling: true
//         maxCount: 3
//         maxPods: 30
//         minCount: 1
//         mode: 'System'
//         name: 'defaultpool'
//         osDiskSizeGB: 30
//         osType: 'Linux'
//         serviceCidr: ''
//         type: 'VirtualMachineScaleSets'
//         vmSize: 'Standard_D4d_v5'
//         vnetSubnetID: aksSubnet.id
//       }
//     ]
//     autoScalerProfileBalanceSimilarNodeGroups: enableAutoScaling ? autoScalingProfile.balanceSimilarNodeGroups : null
//     autoScalerProfileExpander: enableAutoScaling ? autoScalingProfile.expander : null
//     autoScalerProfileMaxEmptyBulkDelete: enableAutoScaling ? autoScalingProfile.maxEmptyBulkDelete : null
//     autoScalerProfileMaxGracefulTerminationSec: enableAutoScaling ? autoScalingProfile.maxGracefulTerminationSec : null
//     autoScalerProfileMaxNodeProvisionTime: enableAutoScaling ? autoScalingProfile.maxNodeProvisionTime : null
//     autoScalerProfileMaxTotalUnreadyPercentage: enableAutoScaling ? autoScalingProfile.maxTotalUnreadyPercentage : null
//     autoScalerProfileNewPodScaleUpDelay: enableAutoScaling ? autoScalingProfile.newPodScaleUpDelay : null
//     autoScalerProfileOkTotalUnreadyCount: enableAutoScaling ? autoScalingProfile.okTotalUnreadyCount : null
//     autoScalerProfileScaleDownDelayAfterAdd: enableAutoScaling ? autoScalingProfile.scaleDownDelayAfterAdd : null
//     autoScalerProfileScaleDownDelayAfterDelete: enableAutoScaling ? autoScalingProfile.scaleDownDelayAfterDelete : null
//     autoScalerProfileScaleDownDelayAfterFailure: enableAutoScaling
//       ? autoScalingProfile.scaleDownDelayAfterFailure
//       : null
//     autoScalerProfileScaleDownUnneededTime: enableAutoScaling ? autoScalingProfile.scaleDownUnneededTime : null
//     autoScalerProfileScaleDownUnreadyTime: enableAutoScaling ? autoScalingProfile.scaleDownUnreadyTime : null
//     autoScalerProfileScanInterval: enableAutoScaling ? autoScalingProfile.scanInterval : null
//     autoScalerProfileSkipNodesWithLocalStorage: enableAutoScaling ? autoScalingProfile.skipNodesWithLocalStorage : null
//     autoScalerProfileSkipNodesWithSystemPods: enableAutoScaling ? autoScalingProfile.skipNodesWithSystemPods : null
//     autoScalerProfileUtilizationThreshold: enableAutoScaling ? autoScalingProfile.scaleDownUtilizationThreshold : null
//     networkPlugin: networkPlugin == 'azure' ? 'azure' : 'kubenet'
//     outboundType: 'loadBalancer'
//     dnsServiceIP: '192.168.100.10'
//     serviceCidr: '192.168.100.0/24'
//     networkPolicy: 'calico'
//     podCidr: networkPlugin == 'kubenet' ? '172.17.0.0/16' : null
//     enablePrivateCluster: true
//     privateDNSZone: pvtdnsAKSZone.id
//     enablePrivateClusterPublicFQDN: false
//     enableRBAC: true
//     aadProfileAdminGroupObjectIDs: [
//       aksadminaccessprincipalId
//     ]
//     kubernetesVersion: kubernetesVersion
//     aadProfileEnableAzureRBAC: true
//     aadProfileManaged: true
//     aadProfileTenantId: subscription().tenantId
//     omsAgentEnabled: true
//     monitoringWorkspaceId: workspace.outputs.resourceId
//     azurePolicyEnabled: true
//     webApplicationRoutingEnabled: true
//     // dnsZoneResourceId: '/subscriptions/029e4694-af3a-4d10-a193-e1cead6586a9/resourceGroups/dns/providers/Microsoft.Network/dnszones/leachlabs6.co.uk'
//     enableDnsZoneContributorRoleAssignment: true
//     // ingressApplicationGatewayEnabled: true
//     // appGatewayResourceId: appGateway.id
//     enableKeyvaultSecretsProvider: true
//     managedIdentities: {
//       userAssignedResourcesIds: [
//         userAssignedIdentity.outputs.resourceId
//       ]
//     }
//   }
//   dependsOn: [
//     dnsPrivateZoneAssignment
//     vnetspoke
//   ]
// }

// // This was added to make deployment work, but didn't appear to be required when using the individual bicep files.
// // Grant the userIdentity used by AKS the "Private DNS Zone Contributor" role on the private zone
// module dnsPrivateZoneAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'dnsPrivateZoneAssignment'
//   params: {
//     principalId: userAssignedIdentity.outputs.principalId
//     resourceId: privateDnsZoneAKS.outputs.resourceId
//     roleDefinitionId: 'b12aa53e-6015-4669-85d0-8515ebb3ae7f'
//     principalType: 'ServicePrincipal'
//   }
// }

// // This was added to make deployment work, but didn't appear to be required when using the individual bicep files.
// // Grant AKS the Network Contributor role on the spoke vnet
// module networkContributorAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'networkContributorAssignment'
//   params: {
//     principalId: userAssignedIdentity.outputs.principalId
//     resourceId: vnetspoke.outputs.resourceId
//     roleDefinitionId: '4d97b98b-1d4f-4787-a291-c67834d212e7'
//     principalType: 'ServicePrincipal'
//   }
// }

// // Give AKS cluster admin rights to use Key Vault.
// module kvAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'keyvault-aks-identity'
//   params: {
//     principalId: managedCluster.outputs.keyvaultIdentityClientId
//     resourceId: vault.outputs.resourceId
//     roleDefinitionId: '00482a5a-887f-4fb3-b363-3b7fe8e74483'
//     principalType: 'ServicePrincipal'
//   }
// }

// // Give AKS the rights to pull from the ACR.
// module acrAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
//   scope: resourceGroup(rgSpoke.name)
//   name: 'acr-aks-identity'
//   params: {
//     principalId: managedCluster.outputs.kubeletidentityObjectId
//     resourceId: registry.outputs.resourceId
//     roleDefinitionId: '7f951dda-4ed3-4680-a7ca-43fe172d538d'
//     principalType: 'ServicePrincipal'
//   }
// }

// /////////////////
// // Testing
// /////////////////

// output firewallName string = azureFirewall.outputs.name
