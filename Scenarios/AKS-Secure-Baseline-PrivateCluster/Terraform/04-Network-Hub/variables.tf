#############
# VARIABLES #
#############

variable "location" {
  default = "eastus"
}

variable "tags" {
  type = map(string)

  default = {
    project = "cs-aks"
  }
}

variable "hub_prefix" {
  default = "escs-hub"
}

variable "sku_name" {
  default = "AZFW_VNet"
}

variable "sku_tier" {
  default = "Standard"
}

## Sensitive Variables for the Jumpbox
## Sample terraform.tfvars File

# admin_password = "ChangeMe"
# admin_username = "sysadmin"
