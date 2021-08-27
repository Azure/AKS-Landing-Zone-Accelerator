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
    resource_group_name  = "tfstatejkc"            # Update this value
    storage_account_name = "tfstatestorejkc"         # Update this value
    container_name       = "escsjkc"              # Update this value
    key                  = "aad"
  }

}

provider "azurerm" {
  features {}
}

