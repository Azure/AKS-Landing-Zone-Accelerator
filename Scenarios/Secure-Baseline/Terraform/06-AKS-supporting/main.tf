#############
# VARIABLES #
#############

variable "access_key" {}

variable "prefix" {
  default = "escs"
}



########
# DATA #
########

# Data From Existing Infrastructure

data "terraform_remote_state" "existing-lz" {
  backend = "azurerm"

  config = {
    storage_account_name = "escstfstate"
    container_name       = "escs"
    key                  = "lz-net"
    access_key = var.access_key
  }
}

data "azurerm_client_config" "current" {}


output "key_vault_id" {
  value = module.create_kv.kv_id
}







