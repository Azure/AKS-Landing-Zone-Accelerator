using 'main.bicep'

param rgName = 'rg-hub'

param availabilityZones = [
  1
  2
  3
]

param hubVnetAddPrefixes = [
  '10.0.0.0/16'
]

param azfwName = 'afw-hub'

param rtVmSubnetName = 'rt-vm-subnet'

param fwNatRuleCollections = []

param vnetHubName = 'vnet-hub'

param defaultSubnetName = 'default'

param nsgBastionName = 'nsg-bastion'

param defaultSubnetAddressPrefix = '10.0.0.0/24'

param azureFirewallSubnetName = 'AzureFirewallSubnet'

param azureFirewallSubnetAddressPrefix = '10.0.1.0/26'

param azureFirewallManagementSubnetName = 'AzureFirewallManagementSubnet'

param azureFirewallManagementSubnetAddressPrefix = '10.0.4.0/26'

param azureBastionSubnetName = 'AzureBastionSubnet'

param azureBastionSubnetAddressPrefix = '10.0.2.0/27'

param vmSubnetName = 'vmsubnet'

param vmSubnetAddressPrefix = '10.0.3.0/24'

param spokeSubnetAksPrefix = '10.1.1.0/24'

param enableTelemetry = true
