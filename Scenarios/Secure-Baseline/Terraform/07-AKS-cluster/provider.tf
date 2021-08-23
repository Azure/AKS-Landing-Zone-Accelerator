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
    resource_group_name  = "tfstate"       # Update this variable
    storage_account_name = "tfstate-sa"    # Update this variable
    container_name       = "akscs"         # Update this variable
    key                  = "aks"
  }
}

provider "azurerm" {
  features {}
}

