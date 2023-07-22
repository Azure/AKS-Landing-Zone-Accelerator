#############
# VARIABLES #
#############

## AKS security groups ##

variable "aks_admin_group" {
  default = "AKS App Admin Jose Team 2"
}

variable "aks_user_group" {
  default = "AKS App Dev Jose Team 2"
}

variable "subscription_id" {
  description = "Azure subscription Id."
  default     = null
}

## Following Variables are for TF State storage account information used for Terraform state file"

variable "resource_group_name" {
  default = "tfstate"
}

variable "storage_account_name" {
  default = "winaksdc"

}

variable "container_name" {
  default = "akscs"
}
