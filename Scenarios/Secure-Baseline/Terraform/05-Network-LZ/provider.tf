terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.46.1"
    }

  }
  
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "escstfstate"
    container_name       = "escs"
    key                  = "lz-net"
  }
}

provider "azurerm" {
  features {}
}

