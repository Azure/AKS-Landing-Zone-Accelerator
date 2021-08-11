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
    storage_account_name = "tfstate09102021"
    container_name       = "akscs"
    key                  = "aks-support"
  }
}

provider "azurerm" {
  features {}
}
