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
    key = "aks"
  }
}

provider "azurerm" {
  features {}
  disable_terraform_partner_id = false
  partner_id                   = "5c162503-e576-4058-b2b4-2d4fd32d3584"
}
