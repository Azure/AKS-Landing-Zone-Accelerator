using 'main.bicep'

param rgName = 'rg-spoke'

param vnetSpokeName = 'vnet-spoke'

param spokeVnetAddPrefixes = [
  '10.1.0.0/16'
]

param rtAksSubnetName = 'rt-aks'

param firewallIp = '10.0.1.4'

param vnetHubName = 'vnet-hub'

param agcName = 'alb-controller'

param vnetHubRgName = 'rg-hub'

param nsgAksName = 'nsg-aks'

param enablePrivateCluster = true

param securityRules = []

param spokeSubnetVmPrefix = '10.1.3.0/24'

param spokeSubnetPLinkervicePrefix = '10.1.4.0/24'

param remotePeeringName = 'spoke-hub-peering'

param vmSize = 'Standard_DS2_v2'

// Jumpbox VM password — set JUMPBOX_PASSWORD environment variable before deploying
param jumpboxAdminPassword = readEnvironmentVariable('JUMPBOX_PASSWORD', '')
