targetScope = 'subscription'

// Parameters
@description('The name of the resource group for the hub network.')
param rgName string

@description('The name of the hub virtual network.')
param vnetHubName string

@description('The address prefixes for the hub virtual network.')
param hubVNETaddPrefixes array

@description('The name of the Azure Firewall.')
param azfwName string

@description('The name of the route table for the VM subnet.')
param rtVMSubnetName string

@description('NAT rule collections for Azure Firewall.')
param fwnatRuleCollections array

@description('The Azure region for all resources.')
param location string = deployment().location

@description('The availability zones to deploy resources into.')
param availabilityZones array

@description('The name of the default subnet in the hub VNet.')
param defaultSubnetName string

@description('The address prefix for the default subnet.')
param defaultSubnetAddressPrefix string

@description('The name of the Azure Firewall subnet.')
param azureFirewallSubnetName string

@description('The address prefix for the Azure Firewall subnet.')
param azureFirewallSubnetAddressPrefix string

@description('The name of the Azure Firewall management subnet.')
param azureFirewallManagementSubnetName string

@description('The address prefix for the Azure Firewall management subnet.')
param azureFirewallManagementSubnetAddressPrefix string

@description('The name of the Azure Bastion subnet.')
param azureBastionSubnetName string

@description('The address prefix for the Azure Bastion subnet.')
param azureBastionSubnetAddressPrefix string

@description('The name of the VM subnet.')
param vmsubnetSubnetName string

@description('The address prefix for the VM subnet.')
param vmsubnetSubnetAddressPrefix string

@description('The name of the NSG for the Bastion subnet.')
param nsgBastionName string

@description('The prefix for the spoke subnet AKS')
param spokeSubnetAKSPrefix string = '10.1.1.0/24'


module rg 'br/public:avm/res/resources/resource-group:0.4.3' = {
  name: rgName
  params: {
    name: rgName
    location: location
    enableTelemetry: true
  }
}

module virtualNetwork 'br/public:avm/res/network/virtual-network:0.7.2' = {
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
        networkSecurityGroupResourceId: networkSecurityGroupBastion.outputs.resourceId
      }
      {
        name: vmsubnetSubnetName
        addressPrefix: vmsubnetSubnetAddressPrefix
      }
    ]
    enableTelemetry: true
  }
}

module networkSecurityGroupBastion 'br/public:avm/res/network/network-security-group:0.5.2' = {
  scope: resourceGroup(rg.name)
  name: nsgBastionName
  params: {
    name: nsgBastionName
    location: location
    securityRules: [
      {
        name: 'AllowHttpsInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 120
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowRdpInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '3389'
          direction: 'Inbound'
          priority: 121
          protocol: 'Tcp'
          sourceAddressPrefix: '178.85.26.64'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowSshInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
          direction: 'Inbound'
          priority: 122
          protocol: 'Tcp'
          sourceAddressPrefix: '178.85.26.64'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowGatewayManagerInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 130
          protocol: 'Tcp'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowAzureLoadBalancerInbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
          direction: 'Inbound'
          priority: 140
          protocol: 'Tcp'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Inbound'
          priority: 150
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowSshRdpOutbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          direction: 'Outbound'
          priority: 100
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowAzureCloudOutbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
          direction: 'Outbound'
          priority: 110
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          direction: 'Outbound'
          priority: 120
          protocol: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
        }
      }
      {
        name: 'AllowHttpOutbound'
        properties: {
          access: 'Allow'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '80'
          direction: 'Outbound'
          priority: 130
          protocol: '*'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }

    ]
    enableTelemetry: true
  }
}


module publicIpFW 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-PIP'
  params: {
    name: 'AZFW-PIP'
    location: location
    availabilityZones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicIpFWMgmt 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  scope: resourceGroup(rg.name)
  name: 'AZFW-Management-PIP'
  params: {
    name: 'AZFW-Management-PIP'
    location: location
    availabilityZones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module publicipbastion 'br/public:avm/res/network/public-ip-address:0.12.0' = {
  scope: resourceGroup(rg.name)
  name: 'publicipbastion'
  params: {
    name: 'publicipbastion'
    location: location
    availabilityZones: availabilityZones
    publicIPAllocationMethod: 'Static'
    skuName: 'Standard'
    skuTier: 'Regional'
    enableTelemetry: true
  }
}

module bastionHost 'br/public:avm/res/network/bastion-host:0.8.2' = {
  scope: resourceGroup(rg.name)
  name: 'bastion'
  params: {
    name: 'bastion'
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    bastionSubnetPublicIpResourceId: publicipbastion.outputs.resourceId
    location: location
    enableTelemetry: true
  }
}

module routeTable 'br/public:avm/res/network/route-table:0.5.0' = {
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


module azureFirewall 'br/public:avm/res/network/azure-firewall:0.10.0' = {
  scope: resourceGroup(rg.name)
  name: azfwName
  params: {
    name: azfwName
    location: location
    virtualNetworkResourceId: virtualNetwork.outputs.resourceId
    availabilityZones: availabilityZones
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


// Defining firewall config here so that the spokeSubnetAKSPrefix can be passed dynamically
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
            '*.blob.${environment().suffixes.storage}'
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
