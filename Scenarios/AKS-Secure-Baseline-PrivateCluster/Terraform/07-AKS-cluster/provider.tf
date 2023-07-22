terraform {
  required_version = "~> 1.4.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.39.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.58.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.3.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = var.resource_group_name  # Partial configuration, provided during "terraform init"
    storage_account_name = var.storage_account_name # Partial configuration, provided during "terraform init"
    container_name       = var.container_name       # Partial configuration, provided during "terraform init"
    key                  = "aks"
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {
}
