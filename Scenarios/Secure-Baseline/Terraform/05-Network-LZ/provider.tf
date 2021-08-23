terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.46.1"
    }

  }
  
  backend "azurerm" {
    resource_group_name  = "tfstate"       # Update this value
    storage_account_name = "tfstate-sa"    # Update this value
    container_name       = "akscs"         # Update this value
    key                  = "lz-net"
  }
}

provider "azurerm" {
  features {}
}

