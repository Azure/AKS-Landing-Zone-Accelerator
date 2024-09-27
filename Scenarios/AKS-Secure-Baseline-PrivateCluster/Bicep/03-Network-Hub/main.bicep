targetScope = 'subscription'

// Parameters
param rgName string
param vnetHubName string
param hubVNETaddPrefixes array
param azfwName string
param rtVMSubnetName string
param fwnatRuleCollections array
param location string = deployment().location
param availabilityZones array
param defaultSubnetName string
param defaultSubnetAddressPrefix string
param azureFirewallSubnetName string
param azureFirewallSubnetAddressPrefix string
param azureFirewallManagementSubnetName string
param azureFirewallManagementSubnetAddressPrefix string
param azureBastionSubnetName string
param azureBastionSubnetAddressPrefix string
param vmsubnetSubnetName string
param vmsubnetSubnetAddressPrefix string

@description('The prefix for the spoke subnet AKS')
param spokeSubnetAKSPrefix string = '10.1.1.0/24'


module rg 'br/public:avm/res/resources/resource-group:0.2.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: vnetHubName
  params: {
    addressPrefixes: hubVNETaddPrefixes
    name: vnetHubName
    location: location
    subnets: [
      {
        name: defaultSubnetName
        addressPrefix: defaultSubnetAddressPrefix
      }
      {
        name: azureFirewallSubnetName
        addressPrefix: azureFirewallSubnetAddressPrefix
      }
      {
        name: azureFirewallManagementSubnetName
        addressPrefix: azureFirewallManagementSubnetAddressPrefix
      }
      {
        name: azureBastionSubnetName
        addressPrefix: azureBastionSubnetAddressPrefix
      }
      {
        name: vmsubnetSubnetName
        addressPrefix: vmsubnetSubnetAddressPrefix
      }
    ]
    enableTelemetry: true
  }
}

module publicIpFW 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-PIP'
  params: {
    name: 'AZFW-PIP'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicIpFWMgmt 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-Management-PIP'
  params: {
    name: 'AZFW-Management-PIP'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicipbastion 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  scope: resourceGroup(rg.name)
  name: 'publicipbastion'
  params: {
    name: 'publicipbastion'
    location: location
    zones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: 'bastion'
  params: {
    name: 'bastion'
    vNetId: virtualNetwork.outputs.resourceId
    bastionSubnetPublicIpResourceId: publicipbastion.outputs.resourceId
    location: location
    enableTelemetry: true
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.2.2' = {
  scope: resourceGroup(rg.name)
  name: rtVMSubnetName
  params: {
    name: rtVMSubnetName
    location: location
    routes: [
      {
        name: 'vm-to-internet'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: azureFirewall.outputs.privateIp
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}


module azureFirewall 'br/public:avm/res/network/azure-firewall:0.1.1' = {
  scope: resourceGroup(rg.name)
  name: azfwName
  params: {
    name: azfwName
    location: location
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    zones: availabilityZones
    publicIPResourceID: publicIpFW.outputs.resourceId
    managementIPResourceID: publicIpFWMgmt.outputs.resourceId
    applicationRuleCollections: fwapplicationRuleCollections
    natRuleCollections: fwnatRuleCollections
    networkRuleCollections: fwnetworkRuleCollections
  }
}

//  Telemetry Deployment
@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true
var telemetryId = '0d807b2d-f7c3-4710-9a65-e88257df1ea0-${location}'
module telemetry './telemetry.bicep' = {
  scope: resourceGroup(rg.name)
  name: 'telemetry'
  params: {
    enableTelemetry: enableTelemetry
    telemetryId: telemetryId
  }
}


// Defining firewal config here so that the spokeSubnetAKSPrefix can be passed dynamically
// this way, if customer isnt using the default subnetprefix for AKS, they can configure the 
// firewall settings to make it allow AKS deploy successfully by specifying their own subnet prefix
@description('Returns the firewall application rule collections')
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
            spokeSubnetAKSPrefix
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
            spokeSubnetAKSPrefix
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
            spokeSubnetAKSPrefix
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
            spokeSubnetAKSPrefix
          ]
        }
      ]
    }
  }
]

@description('Returns the firewall network rule collections')
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
            spokeSubnetAKSPrefix
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
            spokeSubnetAKSPrefix
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
            spokeSubnetAKSPrefix
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
