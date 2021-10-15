########
# DATA #
########

# Data From Existing Infrastructure

data "terraform_remote_state" "existing-lz" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "lz-net"
    access_key = var.access_key
  }
}

data "terraform_remote_state" "aks-support" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "aks-support"
    access_key = var.access_key
  }
}

data "terraform_remote_state" "aad" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "aad"
    access_key = var.access_key
  }

}

data "terraform_remote_state" "existing-hub" {
  backend = "azurerm"

  config = {
    storage_account_name = var.state_sa_name
    container_name       = var.container_name
    key                  = "hub-net"
    access_key = var.access_key
  }

}

data "azurerm_client_config" "current" {}
