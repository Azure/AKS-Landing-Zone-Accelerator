using 'main.bicep'

param rgName = 'ESLZ-SPOKE-RG'

param vnetSpokeName = 'VNet-SPOKE'

param spokeVNETaddPrefixes = [
  '10.1.0.0/16'
]

param rtAKSSubnetName = 'AKS-RT'

param firewallIP = '10.0.1.4'

param vnetHubName = 'VNet-HUB'

param agcName = 'alb-controller'

param vnetHUBRGName = 'ESLZ-HUB-RG'

param nsgAKSName = 'AKS-NSG'

param enablePrivateCluster = true

param securityRules = []

param spokeSubnetVMPrefix = '10.1.3.0/24'

param spokeSubnetPLinkervicePrefix = '10.1.4.0/24'

param remotePeeringName = 'spoke-hub-peering'

param vmSize = 'Standard_DS2_v2'
