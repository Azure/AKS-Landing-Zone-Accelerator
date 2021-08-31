#############
# VARIABLES #
#############

variable "location" {
  default = "westus2"
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

## Sensitive Variables for the Jumpbox
## Sample terraform.tfvars File

# admin_password = "ChangeMe"
# admin_username = "sysadmin"
