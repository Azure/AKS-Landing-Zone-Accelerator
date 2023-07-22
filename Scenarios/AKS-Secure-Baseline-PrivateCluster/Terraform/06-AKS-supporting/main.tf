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

########
# DATA #
########

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

data "terraform_remote_state" "existing-lz" {
  backend = "azurerm"

  config = {
    storage_account_name = var.storage_account_name
    container_name       = var.container_name
    key                  = "lz-net"
    access_key           = var.access_key
  }
}

data "azurerm_client_config" "current" {}


output "key_vault_id" {
  value = module.create_kv.kv_id
}

output "container_registry_id" {
  value = module.create_acr.acr_id
}











