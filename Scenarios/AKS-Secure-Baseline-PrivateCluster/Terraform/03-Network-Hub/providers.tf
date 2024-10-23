terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # version = "~> 4.6.0"
      version = "~> 3.71"
    }
  }
}

provider "azurerm" {
  # subscription_id = "dcef7009-6b94-4382-afdc-17eb160d709a"
  features {}
}
