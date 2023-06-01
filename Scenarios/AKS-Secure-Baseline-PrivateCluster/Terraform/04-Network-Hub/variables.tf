#############
# VARIABLES #
#############

variable "location" {

  default = "eastus"
}
#variable "firewallName" {}

variable "tags" {
  type = map(string)

  default = {
    project = "cs-aks"
  }
}

variable "sku_name" {
  default = "AZFW_VNet"
}

variable "sku_tier" {
  default = "Standard"
}

## Sensitive Variables for the Jumpbox
## Sample terraform.tfvars File

variable "admin_password" {
  default   = "MSAzure.2023!"
  sensitive = true
}

variable "admin_username" {
  default = "sysadmin"
}

## Terraform backend state variables update with your storage account information ##

variable "resource_group_name" {
  default = "tfstate"
}

variable "storage_account_name" {
  default = "winaksdc"
}

variable "container_name" {
  default = "akscs"
}
