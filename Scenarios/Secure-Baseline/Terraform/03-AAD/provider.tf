# Update the variables in the BACKEND block to refrence the 
# storage account created out of band for TF statemanagement.

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 2.46.1"
    }

  }

  backend "azurerm" {
    resource_group_name  = "tfstate"            # Update this value
    storage_account_name = <unique storage account name>         # Update this value
    container_name       = "akscs"              # Update this value
    key                  = "aad"
  }

}

provider "azurerm" {
  features {}
}

