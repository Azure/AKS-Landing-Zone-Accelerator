terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3"
    }
    random = {
      version = ">=3.0"
    }
  }
  backend "azurerm" {
    # resource_group_name  = ""   # Partial configuration, provided during "terraform init"
    # storage_account_name = ""   # Partial configuration, provided during "terraform init"
    # container_name       = ""   # Partial configuration, provided during "terraform init"
    key                  = "aks-support"
  }
}

provider "azurerm" {
  features {}
}
