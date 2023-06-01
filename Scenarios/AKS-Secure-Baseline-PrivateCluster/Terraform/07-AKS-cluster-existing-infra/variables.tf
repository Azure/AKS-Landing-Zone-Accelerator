#############
# VARIABLES #
#############

variable "dns_prefix" {
  # update this in the .tfvars file
}

variable "storage_account_name" {}

variable "container_name" {}

variable "access_key" {}

variable "private_dns_zone_name" {
  default = "privatelink.eastus.azmk8s.io"
}
