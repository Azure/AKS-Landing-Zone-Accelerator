# Creates cluster with default linux node pool
resource "azurerm_kubernetes_cluster" "akscluster" {
  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count
    ]
  }

  name                      = var.caf_basename.azurerm_kubernetes_cluster
  dns_prefix                = var.dns_prefix
  location                  = var.location
  resource_group_name       = var.resource_group_name
  kubernetes_version        = "1.25.5"
  private_cluster_enabled   = true
  private_dns_zone_id       = var.private_dns_zone_id
  azure_policy_enabled      = true
  local_account_disabled    = true
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }

  default_node_pool {
    name                         = "defaultpool"
    vm_size                      = "Standard_DS2_v2"
    os_disk_size_gb              = 30
    os_disk_type                 = "Ephemeral"
    type                         = "VirtualMachineScaleSets"
    enable_auto_scaling          = true
    min_count                    = 3
    max_count                    = 4
    vnet_subnet_id               = var.vnet_subnet_id
    only_critical_addons_enabled = true
    zones                        = ["1", "2", "3"]
    upgrade_settings {
      max_surge = "33%"
    }
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    outbound_type     = "userDefinedRouting"
    dns_service_ip    = "192.168.100.10"
    service_cidr      = "192.168.100.0/24"
    network_policy    = "azure"
  }

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = [var.aks_admin_group]
    azure_rbac_enabled     = true
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.mi_aks_cp_id]
  }

  oms_agent {
    log_analytics_workspace_id = var.la_id
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "windows_node_pool" {
  name                  = var.caf_basename.aks_node_pool_windows
  kubernetes_cluster_id = azurerm_kubernetes_cluster.akscluster.id
  vm_size               = "Standard_DS4_v2"
  enable_auto_scaling   = true
  min_count             = 2
  max_count             = 5
  mode                  = "User"
  os_disk_type          = "Ephemeral"
  os_type               = "Windows"
  os_sku                = "Windows2019"
  vnet_subnet_id        = var.winnp_subnet_id
  zones                 = ["1", "2", "3"]
  upgrade_settings {
    max_surge = "33%"
  }
  tags = {
    "nodepool-type" = "user"
    "env_type"      = "Windows_np"
    "app"           = "dotnet-apps"
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "linux_user_pool" {
  name                  = var.caf_basename.aks_node_pool_linux
  kubernetes_cluster_id = azurerm_kubernetes_cluster.akscluster.id
  vm_size               = "Standard_DS2_v2"
  os_disk_size_gb       = 30
  os_disk_type          = "Ephemeral"
  enable_auto_scaling   = true
  min_count             = 1
  max_count             = 3
  os_type               = "Linux"
  vnet_subnet_id        = var.vnet_subnet_id
  zones                 = ["1", "2", "3"]
  upgrade_settings {
    max_surge = "33%"
  }
}

#Diagnostic Settings
data "azurerm_monitor_diagnostic_categories" "aks" {
  resource_id = azurerm_kubernetes_cluster.akscluster.id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                           = replace(var.caf_basename.azurerm_monitor_diagnostic_setting, "amds", "aksamds")
  target_resource_id             = azurerm_kubernetes_cluster.akscluster.id
  log_analytics_workspace_id     = var.spoke_la_id
  log_analytics_destination_type = "AzureDiagnostics"

  dynamic "enabled_log" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.aks.log_category_types

    content {
      category = entry.value

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }

  dynamic "metric" {
    iterator = entry
    for_each = data.azurerm_monitor_diagnostic_categories.aks.metrics

    content {
      category = entry.value
      enabled  = true

      retention_policy {
        enabled = true
        days    = 30
      }
    }
  }
}


# Outputs
output "aks_id" {
  value = azurerm_kubernetes_cluster.akscluster.id
}

output "node_pool_rg" {
  value = azurerm_kubernetes_cluster.akscluster.node_resource_group
}

# Managed Identities created for Addons

output "kubelet_id" {
  value = azurerm_kubernetes_cluster.akscluster.kubelet_identity[0].object_id
}
