
data "azurerm_resource_group" "aks_nodes_rg" {
  name  = var.aks_nodes_resource_group_name
}

data "azurerm_resource_group" "velero" {
  name  = var.backups_rg_name
}


data "azurerm_storage_account" "velero" {
  name  = var.backups_stracc_name
  resource_group_name  = var.backups_rg_name
}
