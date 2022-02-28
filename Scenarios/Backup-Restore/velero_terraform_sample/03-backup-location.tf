###############
# Resource Group to store disk snapshots + Storage Account to store backup configuration files 
###############

resource "azurerm_resource_group" "aks1_backups" {
  name     = var.backups_rg_name
  location = var.backups_region
  tags     = var.tags
}


resource "azurerm_storage_account" "aks1_backups" {
  name                     = "${local.random_stracc_name}"
  resource_group_name      = azurerm_resource_group.aks1_backups.name
  location                 = azurerm_resource_group.aks1_backups.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  access_tier              = "Hot"
  min_tls_version          = "TLS1_2"

  enable_https_traffic_only = true

  tags = var.tags
}

resource "azurerm_storage_container" "velero" {
  name                  = "velero"
  storage_account_name  = azurerm_storage_account.aks1_backups.name
  container_access_type = "private"
}

