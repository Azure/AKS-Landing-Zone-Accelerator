locals {
  domain_name = {
    akv     = "privatelink.vaultcore.azure.net",
    acr     = "privatelink.azurecr.io",
    aks     = "azmk8s.io"
    contoso = "private.contoso.com"
  }

  vnetLzId         = var.deployingAllInOne == true ? var.vnetLzId : data.azurerm_virtual_network.vnet-lz.0.id
  snetAksId        = var.deployingAllInOne == true ? var.snetAksId : data.azurerm_subnet.snet-aks.0.id
  dnszoneAksId     = var.deployingAllInOne == true ? var.dnszoneAksId : data.azurerm_private_dns_zone.dnszone-aks.0.id
  dnszoneContosoId = var.deployingAllInOne == true ? var.dnszoneContosoId : data.azurerm_private_dns_zone.dnszone-contoso.0.id
  acrId            = var.deployingAllInOne == true ? var.acrId : data.azurerm_container_registry.acr.0.id
  akvId            = var.deployingAllInOne == true ? var.akvId : data.azurerm_key_vault.akv.0.id
}

data "azurerm_client_config" "tenant" {}

# data "azurerm_resource_group" "rg" {
#   name = var.rgLzName
# }

data "azurerm_virtual_network" "vnet-lz" {
  count               = var.deployingAllInOne == true ? 0 : 1
  name                = var.vnetLzName
  resource_group_name = var.rgLzName
}

data "azurerm_subnet" "snet-aks" {
  count                = var.deployingAllInOne == true ? 0 : 1
  name                 = "snet-aks"
  virtual_network_name = var.vnetLzName
  resource_group_name  = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszone-aks" {
  count               = var.deployingAllInOne == true ? 0 : 1
  name                = "privatelink.${var.location}.${local.domain_name.aks}"
  resource_group_name = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszone-contoso" {
  count               = var.deployingAllInOne == true ? 0 : 1
  name                = local.domain_name.contoso
  resource_group_name = var.rgLzName
}

data "azurerm_container_registry" "acr" {
  count               = var.deployingAllInOne == true ? 0 : 1
  name                = var.acrName
  resource_group_name = var.rgLzName
}

data "azurerm_key_vault" "akv" {
  count               = var.deployingAllInOne == true ? 0 : 1
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
  location            = var.location # data.azurerm_resource_group.rg.location
  resource_group_name = var.rgLzName # data.azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "role-assignment-dnszone" {
  scope                = local.dnszoneAksId # data.azurerm_private_dns_zone.dnszone-aks.id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = module.avm-res-managedidentity-userassignedidentity.principal_id
}

resource "azurerm_role_assignment" "role-assignment-vnetcontrib" {
  scope                = local.vnetLzId # data.azurerm_virtual_network.vnet-lz.id
  role_definition_name = "Network Contributor"
  principal_id         = module.avm-res-managedidentity-userassignedidentity.principal_id
}

module "avm-res-operationalinsights-workspace" {
  source                                    = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version                                   = "0.4.1"
  name                                      = module.naming.log_analytics_workspace.name_unique
  resource_group_name                       = var.rgLzName # data.azurerm_resource_group.rg.name
  location                                  = var.location # data.azurerm_resource_group.rg.location
  log_analytics_workspace_retention_in_days = 30
  log_analytics_workspace_sku               = "PerGB2018"
  log_analytics_workspace_identity = {
    type = "SystemAssigned"
  }
}

resource "azurerm_kubernetes_cluster" "aks-cluster" {
  name                              = module.naming.kubernetes_cluster.name_unique
  resource_group_name               = var.rgLzName # data.azurerm_resource_group.rg.name
  location                          = var.location # data.azurerm_resource_group.rg.location
  dns_prefix_private_cluster        = module.naming.kubernetes_cluster.name_unique
  private_cluster_enabled           = true
  private_dns_zone_id               = local.dnszoneAksId # data.azurerm_private_dns_zone.dnszone-aks.id
  azure_policy_enabled              = true
  kubernetes_version                = "1.30"
  local_account_disabled            = true
  oidc_issuer_enabled               = true
  sku_tier                          = "Standard"
  workload_identity_enabled         = true
  automatic_upgrade_channel        = "patch"
  role_based_access_control_enabled = true
  #http_application_routing_enabled  = true

  web_app_routing {
    dns_zone_ids = [local.dnszoneContosoId] # data.azurerm_private_dns_zone.dnszone-contoso.id]
  }
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = true
    admin_group_object_ids = [var.adminGroupObjectIds]
  }

  default_node_pool {
    name                         = "default"
    vm_size                      = "Standard_DS2_v2"
    os_disk_size_gb              = 30
    os_sku                       = "Ubuntu"
    min_count                    = 1
    max_count                    = 3
    auto_scaling_enabled         = true
    max_pods                     = 110
    only_critical_addons_enabled = true
    vnet_subnet_id               = local.snetAksId

    zones = ["1", "2", "3"]
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

  lifecycle {
    ignore_changes = [ default_node_pool.0.upgrade_settings ]
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "nodepool" {
  name                  = "user"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks-cluster.id
  vm_size               = "Standard_DS2_v2"
  os_disk_size_gb       = 30
  os_sku                = "Ubuntu"
  min_count             = 1
  max_count             = 3
  auto_scaling_enabled  = true
  max_pods              = 250
  mode                  = "User"
  vnet_subnet_id        = local.snetAksId
  zones                 = ["1", "2", "3"]
}

resource "azurerm_role_assignment" "role-assignment-acr" {
  principal_id                     = azurerm_kubernetes_cluster.aks-cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = local.acrId
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role-assignment-akv" {
  principal_id                     = azurerm_kubernetes_cluster.aks-cluster.key_vault_secrets_provider[0].secret_identity[0].object_id
  role_definition_name             = "Key Vault Secrets User"
  scope                            = local.akvId
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "role-assignment-private-dns" {
  principal_id                     = azurerm_kubernetes_cluster.aks-cluster.web_app_routing[0].web_app_routing_identity[0].object_id
  role_definition_name             = "Private DNS Zone Contributor"
  scope                            = local.dnszoneContosoId
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

