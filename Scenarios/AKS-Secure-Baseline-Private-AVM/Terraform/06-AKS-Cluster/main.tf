locals {
  domain_name = {
    akv     = "privatelink.vaultcore.azure.net",
    acr     = "privatelink.azurecr.io",
    aks     = "azmk8s.io"
    contoso = "contoso.com"

  }
}

data "azurerm_client_config" "tenant" {}

data "azurerm_resource_group" "rg" {
  name = var.rgLzName
}

data "azurerm_virtual_network" "vnet-lz" {
  name                = var.vnetLzName
  resource_group_name = var.rgLzName
}

data "azurerm_subnet" "snet-aks" {
  name                 = "snet-aks"
  virtual_network_name = var.vnetLzName
  resource_group_name  = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszone-aks" {
  name                = "privatelink.${var.location}.${local.domain_name.aks}"
  resource_group_name = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszonme-contoso" {
  name                = local.domain_name.contoso
  resource_group_name = var.rgLzName
}
data "azurerm_container_registry" "acr" {
  name                = var.acrName
  resource_group_name = var.rgLzName
}

data "azurerm_key_vault" "akv" {
  name                = var.akvName
  resource_group_name = var.rgLzName
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["lz"]
}

module "avm-res-managedidentity-userassignedidentity" {
  source              = "Azure/avm-res-managedidentity-userassignedidentity/azurerm"
  version             = "0.3.3"
  name                = module.naming.user_assigned_identity.name_unique
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "role-assignment-dnszone" {
  scope                = data.azurerm_private_dns_zone.dnszone-aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = module.avm-res-managedidentity-userassignedidentity.principal_id
}

resource "azurerm_role_assignment" "role-assignment-vnetcontrib" {
  scope                = data.azurerm_virtual_network.vnet-lz.id
  role_definition_name = "Network Contributor"
  principal_id         = module.avm-res-managedidentity-userassignedidentity.principal_id
}

module "avm-res-operationalinsights-workspace" {
  source                                    = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version                                   = "0.4.1"
  name                                      = module.naming.log_analytics_workspace.name_unique
  resource_group_name                       = data.azurerm_resource_group.rg.name
  location                                  = data.azurerm_resource_group.rg.location
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                              = module.naming.kubernetes_cluster.name_unique
  resource_group_name               = data.azurerm_resource_group.rg.name
  location                          = data.azurerm_resource_group.rg.location
  dns_prefix_private_cluster        = module.naming.kubernetes_cluster.name_unique
  private_cluster_enabled           = true
  private_dns_zone_id               = data.azurerm_private_dns_zone.dnszone-aks.id
  azure_policy_enabled              = true
  kubernetes_version                = "1.30"
  local_account_disabled            = true
  oidc_issuer_enabled               = true
  sku_tier                          = "Standard"
  workload_identity_enabled         = true
  automatic_channel_upgrade         = "patch"
  role_based_access_control_enabled = true
  http_application_routing_enabled  = true

  web_app_routing {
    dns_zone_ids = [data.azurerm_private_dns_zone.dnszonme-contoso.id]
  }


  azure_active_directory_role_based_access_control {
    managed                = true
    admin_group_object_ids = [var.admin-group-object-ids]
  }




  default_node_pool {
    name                         = "default"
    vm_size                      = "Standard_DS2_v2"
    os_disk_size_gb              = 30
    os_sku                       = "Ubuntu"
    min_count                    = 1
    max_count                    = 3
    enable_auto_scaling          = true
    max_pods                     = 110
    only_critical_addons_enabled = true
    vnet_subnet_id               = data.azurerm_subnet.snet-aks.id

    zones = [
      "1",
      "2",
      "3",
    ]
  }
  auto_scaler_profile {
    balance_similar_node_groups = true
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }

  identity {
    type = "UserAssigned"
    identity_ids = [
      module.avm-res-managedidentity-userassignedidentity.resource.id,
    ]
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    load_balancer_sku   = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = module.avm-res-operationalinsights-workspace.resource.id
  }

  depends_on = [
    azurerm_role_assignment.role-assignment-dnszone,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "nodepool" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  vm_size               = "Standard_DS2_v2"
  os_disk_size_gb       = 30
  os_sku                = "Ubuntu"
  min_count             = 1
  max_count             = 3
  enable_auto_scaling   = true
  max_pods              = 250
  mode                  = "User"
  vnet_subnet_id        = data.azurerm_subnet.snet-aks.id
  zones = [
    "1",
    "2",
    "3",
  ]
}

resource "azurerm_role_assignment" "role-assignment-acr" {
  principal_id                     = module.avm-res-managedidentity-userassignedidentity.principal_id
  role_definition_name             = "AcrPull"
  scope                            = data.azurerm_container_registry.acr.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role-assignment-akv" {
  principal_id                     = module.avm-res-managedidentity-userassignedidentity.principal_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = data.azurerm_key_vault.akv.id
  skip_service_principal_aad_check = true
}

resource "azurerm_monitor_diagnostic_setting" "diagnostic-aks" {
  name                       = module.naming.monitor_diagnostic_setting.name_unique
  target_resource_id         = azurerm_kubernetes_cluster.aks-cluster.id
  log_analytics_workspace_id = module.avm-res-operationalinsights-workspace.resource.id

  enabled_log {
    category = "kube-apiserver"
  }

  enabled_log {
    category = "kube-controller-manager"
  }

  enabled_log {
    category = "kube-scheduler"
  }

  enabled_log {
    category = "kube-audit"
  }

  enabled_log {
    category = "kube-audit-admin"
  }

  enabled_log {
    category = "cluster-autoscaler"
  }

  enabled_log {
    category = "guard"
  }

  enabled_log {
    category = "csi-azuredisk-controller"
  }

  enabled_log {
    category = "csi-azurefile-controller"
  }

  enabled_log {
    category = "csi-snapshot-controller"
  }

  metric {
    category = "AllMetrics"
  }
}
