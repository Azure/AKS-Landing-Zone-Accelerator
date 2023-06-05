##############
# CAF MODULE #
##############

module "CAFResourceNames" {
  source      = "../00-Naming-module"
  workload    = "rate"
  environment = "dev"
  region      = "eus"
  instance    = "001"
}

# Data From Existing Infrastructure

data "terraform_remote_state" "existing-hub" {
  backend = "azurerm"

  config = {
    storage_account_name = var.storage_account_name
    container_name       = var.container_name
    key                  = "hub-net"
    access_key           = var.access_key
  }
}












