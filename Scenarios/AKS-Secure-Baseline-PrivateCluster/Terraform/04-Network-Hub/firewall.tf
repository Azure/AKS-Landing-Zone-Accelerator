
# Azure Firewall 
# --------------
# Firewall Rules created via Module

resource "azurerm_public_ip" "firewall" {
  count               = "3"
  name                = replace(module.CAFResourceNames.names.azurerm_public_ip, module.CAFResourceNames.instance, "00${count.index + 1}")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
}

resource "azurerm_firewall" "firewall" {
  name                = module.CAFResourceNames.names.azurerm_firewall
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  firewall_policy_id  = module.firewall_rules_aks.fw_policy_id
  sku_name            = var.sku_name
  sku_tier            = var.sku_tier
  zones               = ["1", "2", "3"]

  ip_configuration {
    name                 = replace(module.CAFResourceNames.names.azurerm_firewall, "fw", "fwpip1")
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }

  ip_configuration {
    name                 = replace(module.CAFResourceNames.names.azurerm_firewall, "fw", "fwpip2")
    public_ip_address_id = azurerm_public_ip.firewall[1].id
  }

  ip_configuration {
    name                 = replace(module.CAFResourceNames.names.azurerm_firewall, "fw", "fwpip3")
    public_ip_address_id = azurerm_public_ip.firewall[2].id
  }
}
resource "azurerm_ip_group" "ipg-lxnp" {
  name                = replace(module.CAFResourceNames.names.azurerm_subnet, "snet", "ipg-linux")
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  cidrs = ["10.240.0.0/22"]
}

resource "azurerm_ip_group" "ipg-lxunp" {
  name                = replace(module.CAFResourceNames.names.azurerm_subnet, "snet", "ipg-lxuser")
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  cidrs = ["10.240.5.0/24"]
}

module "firewall_rules_aks" {
  source = "./modules/aks-fw-rules"

  caf_basename        = module.CAFResourceNames.names
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  firewallName        = azurerm_firewall.firewall.name
  lx_ip_group         = azurerm_ip_group.ipg-lxnp.id
  lxu_ip_group        = azurerm_ip_group.ipg-lxunp.id
}


# Diagnostic setting for Firewall
resource "azurerm_monitor_diagnostic_setting" "firewall" {
  name                           = replace(module.CAFResourceNames.names.azurerm_monitor_diagnostic_setting, "amds", "fwamds")
  target_resource_id             = azurerm_firewall.firewall.id
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

# Diagnostic setting for Firewall public ip addresses
resource "azurerm_monitor_diagnostic_setting" "fwpip" {
  count                          = "3"
  name                           = replace(replace(module.CAFResourceNames.names.azurerm_monitor_diagnostic_setting, "amds", "pipamds"), module.CAFResourceNames.instance, "00${count.index + 1}")
  target_resource_id             = azurerm_public_ip.firewall[count.index].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.hub.id
  log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category_group = "audit"

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
