terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.46.1"
    }

  }

  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate09102021"
    container_name       = "akscs"
    key                  = "hub-net"
  }

}

provider "azurerm" {
  features {}
}

