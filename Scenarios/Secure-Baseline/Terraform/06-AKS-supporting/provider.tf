terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.61"
    }
    random = {
      version = ">=3.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "escstfstate"
    container_name       = "escs"
    key                  = "aks-support"
  }
}

provider "azurerm" {
  features {}
}
