terraform {

  required_version = ">= 1.2.8"

  required_providers {

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.6.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "0.10.0"
    }
  }
}

provider "azurerm" {
  subscription_id = "dcef7009-6b94-4382-afdc-17eb160d709a"
  features {}
}

provider "time" {
  # Configuration options
}
