# Firewall Policy

resource "azurerm_firewall_policy" "aks" {
  name                = var.caf_basename.azurerm_firewall_policy
  resource_group_name = var.resource_group_name
  location            = var.location
}

output "fw_policy_id" {
  value = azurerm_firewall_policy.aks.id
}

# Rules Collection Group

resource "azurerm_firewall_policy_rule_collection_group" "AKS" {
  name               = var.caf_basename.azurerm_firewall_policy_rule_collection_group
  firewall_policy_id = azurerm_firewall_policy.aks.id
  priority           = 200

  application_rule_collection {
    name     = "aks_app_global_rules"
    priority = 200
    action   = "Allow"
    rule {
      name = "aks_service"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups      = [var.lx_ip_group, var.win_ip_group]
      destination_fqdn_tags = [
        "AzureKubernetesService"
        ]
    }
  }

  application_rule_collection {
    name     = "aks_app_linux_node_rules"
    priority = 201
    action   = "Allow"
    rule {
      name = "linux_node_pools"
      protocols {
        type = "Http"
        port = 80
      }
      source_ip_groups = [var.lx_ip_group]
      destination_fqdns = [
        "security.ubuntu.com",
        "azure.archive.ubuntu.com",
        "changelogs.ubuntu.com"
      ]
    }
  }

    application_rule_collection {
    name     = "aks_app_win_node_rules"
    priority = 202
    action   = "Allow"
    rule {
      name = "win_node_pools"
      protocols {
        type = "Http"
        port = 80
      }
      protocols {
        type = "Https"
        port = 443
      }

      source_ip_groups = [var.win_ip_group]
      destination_fqdns = [
        "onegetcdn.azureedge.net",
        "go.microsoft.com",
        "*.mp.microsoft.com",
        "www.msftconnecttest.com",
        "ctldl.windowsupdate"
      ]
    }
  }

  application_rule_collection {
    name     = "monitor_containers_rule"
    priority = 203
    action   = "Allow"
    rule {
      name = "monitor_containers"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.lx_ip_group, var.win_ip_group]
      destination_fqdns = [
        "dc.services.visualstudio.com",
        "*.ods.opinsights.azure.com",
        "*.oms.opinsights.azure.com",
        "*.monitoring.azure.com"
      ]
    }
  }

  application_rule_collection {
    name     = "azure_policy_rules"
    priority = 204
    action   = "Allow"
    rule {
      name = "azure_policy"
      protocols {
        type = "Https"
        port = 443
      }
      source_ip_groups = [var.lx_ip_group, var.win_ip_group]
      destination_fqdns = [
        "data.policy.core.windows.net",
        "store.policy.core.windows.net",
        "dc.services.visualstudio.com"
      ]
    }
  }

  network_rule_collection {
      name     = "network_rules"
      priority = 100
      action   = "Allow"
      rule {
       name                  = "net_monitor_containers"
       protocols             = ["TCP"]
       source_ip_groups      = [var.lx_ip_group, var.win_ip_group]
       destination_addresses = ["AzureMonitor"]
       destination_ports     = ["443"]
    }
  }
}

##########################################################
## Common Naming Variable
##########################################################

variable "caf_basename" {}
variable "resource_group_name" {}
variable "location" {}
variable "firewallName" {}
variable "win_ip_group" {}
variable "lx_ip_group" {}
