using 'main.bicep'

param rgName = 'ESLZ-HUB-RG'

param availabilityZones = [
  1
  2
  3
]

param hubVNETaddPrefixes = [
  '10.0.0.0/16'
]

param azfwName = 'AZFW'

param rtVMSubnetName = 'vm-subnet-rt'

param fwnatRuleCollections = []

param vnetHubName = 'VNet-HUB'

param defaultSubnetName = 'default'

param nsgBastionName = 'NSG-Bastion'

param defaultSubnetAddressPrefix = '10.0.0.0/24'

param azureFirewallSubnetName = 'AzureFirewallSubnet'

param azureFirewallSubnetAddressPrefix = '10.0.1.0/26'

param azureFirewallManagementSubnetName = 'AzureFirewallManagementSubnet'

param azureFirewallManagementSubnetAddressPrefix = '10.0.4.0/26'

param azureBastionSubnetName = 'AzureBastionSubnet'

param azureBastionSubnetAddressPrefix = '10.0.2.0/27'

param vmsubnetSubnetName = 'vmsubnet'

param vmsubnetSubnetAddressPrefix = '10.0.3.0/24'

param spokeSubnetAKSPrefix = '10.1.1.0/24'

param enableTelemetry = true
