# Resource Group for Landing Zone Networking
# This RG uses the same region location as the Hub.
resource "azurerm_resource_group" "spoke-rg" {
  name     = replace(module.CAFResourceNames.names.azurerm_resource_group, "rg", "${var.lz_prefix}rg")
  location = data.terraform_remote_state.existing-hub.outputs.hub_rg_location
}

# Virtual Network

resource "azurerm_virtual_network" "vnet" {
  name                = replace(module.CAFResourceNames.names.azurerm_virtual_network, "vnet", "${var.lz_prefix}vnet")
  resource_group_name = azurerm_resource_group.spoke-rg.name
  location            = azurerm_resource_group.spoke-rg.location
  address_space       = ["10.240.0.0/16"]
  dns_servers         = ["10.200.0.100"]
  tags                = var.tags

}

resource "azurerm_subnet" "priv-link" {
  name                                      = module.CAFResourceNames.names.azurerm_subnet
  resource_group_name                       = azurerm_resource_group.spoke-rg.name
  virtual_network_name                      = azurerm_virtual_network.vnet.name
  address_prefixes                          = ["10.240.4.32/28"]
  private_endpoint_network_policies_enabled = true

}

# # Create Route Table for Landing Zone
# (All subnets in the landing zone will need to connect to this Route Table)
resource "azurerm_route_table" "route_table" {
  name                          = replace(module.CAFResourceNames.names.azurerm_route_table, "rt", "${var.lz_prefix}rt")
  resource_group_name           = azurerm_resource_group.spoke-rg.name
  location                      = azurerm_resource_group.spoke-rg.location
  disable_bgp_route_propagation = false

  route {
    name                   = module.CAFResourceNames.names.azurerm_route
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = "10.200.0.4"
  }
}

#############################
## Build Azure front door CDN ##
#############################
module "cdn" {
  source = "./modules/cdn"

  caf_basename               = module.CAFResourceNames.names
  rg                         = azurerm_resource_group.spoke-rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.spokeLA.id
}

# Diagnostic setting for Spoke vnet
resource "azurerm_monitor_diagnostic_setting" "spoke-vnet" {
  name                           = replace(module.CAFResourceNames.names.azurerm_monitor_diagnostic_setting, "amds", "${var.lz_prefix}vntamds")
  target_resource_id             = azurerm_virtual_network.vnet.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.spokeLA.id
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
output "lz_rg_location" {
  value = azurerm_resource_group.spoke-rg.location
}

output "lz_rg_name" {
  value = azurerm_resource_group.spoke-rg.name
}

output "lz_rg_id" {
  value = azurerm_resource_group.spoke-rg.id
}
output "lz_vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "lz_vnet_id" {
  value = azurerm_virtual_network.vnet.id
}

output "priv_subnet_id" {
  value = azurerm_subnet.priv-link.id
}
output "lz_rt_id" {
  value = azurerm_route_table.route_table.id
}
