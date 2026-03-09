using 'main.bicep'

param rgName = 'ESLZ-SPOKE-RG'

param vnetSpokeName = 'VNet-SPOKE'

param spokeVNETaddPrefixes = [
  '10.1.0.0/16'
]

param rtAKSSubnetName = 'AKS-RT'

param firewallIP = '10.0.1.4'

param vnetHubName = 'VNet-HUB'

param appGatewayName = 'APPGW'

param vnetHUBRGName = 'ESLZ-HUB-RG'

param nsgAKSName = 'AKS-NSG'

param nsgAppGWName = 'APPGW-NSG'

param rtAppGWSubnetName = 'AppGWSubnet-RT'

param enablePrivateCluster = true

param availabilityZones = [
  1
  2
  3
]

param appGwyAutoScale = {
  maxCapacity: 2
  minCapacity: 1
}

param securityRules = []

param spokeSubnetDefaultPrefix = '10.1.0.0/24'

param spokeSubnetAKSPrefix = '10.1.1.0/24'

param spokeSubnetAppGWPrefix = '10.1.2.0/27'

param spokeSubnetVMPrefix = '10.1.3.0/24'

param spokeSubnetPLinkervicePrefix = '10.1.4.0/24'

param remotePeeringName = 'spoke-hub-peering'

param vmSize = 'Standard_DS2_v2'
