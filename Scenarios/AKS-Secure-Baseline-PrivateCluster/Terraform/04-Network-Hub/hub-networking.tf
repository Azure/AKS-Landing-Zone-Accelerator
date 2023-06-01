
# Virtual Network for Hub
# -----------------------

resource "azurerm_virtual_network" "vnet" {
  name                = module.CAFResourceNames.names.azurerm_virtual_network
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  address_space       = ["10.200.0.0/24"]
  dns_servers         = ["10.200.0.100"]
  tags                = var.tags

}

# SUBNETS on Hub Network
# ----------------------

# Firewall Subnet
# (Additional subnet for Azure Firewall, without NSG as per Firewall requirements)
resource "azurerm_subnet" "firewall" {
  name                                      = "AzureFirewallSubnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.200.0.0/26"]
  private_endpoint_network_policies_enabled = false

}

# Gateway Subnet 
# (Additional subnet for Gateway, without NSG as per requirements)
resource "azurerm_subnet" "gateway" {
  name                                      = "GatewaySubnet"
  resource_group_name                       = azurerm_resource_group.rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.200.0.64/27"]
  private_endpoint_network_policies_enabled = false

}

# Bastion - Module creates additional subnet (without NSG), public IP and Bastion
module "bastion" {
  source = "./modules/bastion"

  caf_basename               = module.CAFResourceNames.names
  subnet_cidr                = "10.200.0.128/26"
  virtual_network_name       = azurerm_virtual_network.vnet.name
  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.hub.id
}

# Log Analytics Workspace for regional hub network, its spokes, and bastion.
resource "azurerm_log_analytics_workspace" "hub" {
  name                = module.CAFResourceNames.names.azurerm_log_analytics_workspace
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Diagnostic setting for Hub vnet
resource "azurerm_monitor_diagnostic_setting" "hub-vnet" {
  name                           = replace(module.CAFResourceNames.names.azurerm_monitor_diagnostic_setting, "amds", "vntamds")
  target_resource_id             = azurerm_virtual_network.vnet.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.hub.id
  log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category_group = "allLogs"

    retention_policy {
      enabled = true
      days    = "30"
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = "30"
    }
  }
}

#############
## OUTPUTS ##
#############
# These outputs are used by later deployments

output "hub_vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "hub_vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
