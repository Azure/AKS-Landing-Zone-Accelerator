terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.46.1"
    }

  }
  
  backend "azurerm" {
    resource_group_name  = "tfstatejkc"            # Update this value
    storage_account_name = "tfstatestorejkc"         # Update this value
    container_name       = "escsjkc"              # Update this value
    key                  = "lz-net"
  }
}

provider "azurerm" {
  features {}
}

