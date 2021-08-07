# Data From Existing Infrastructure

data "terraform_remote_state" "existing-hub" {
  backend = "azurerm"

  config = {
    storage_account_name = "escstfstate"
    container_name       = "escs"
    key                  = "hub-net"
    access_key = var.access_key
  }

}

# Variables for Spoke/LZ 

variable "tags" {
  type = map(string)

  default = {
    project = "spoke-lz"
  }
}

variable "lz_prefix" {
  default = "escs-lz01"
}

variable "access_key" {}

variable "state_sa_name" {}

variable "container_name" {}















