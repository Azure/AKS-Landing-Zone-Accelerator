##########################################################
## Common Naming Variable
##########################################################

variable "caf_basename" {}

variable "dns_prefix" {}

variable "location" {
  description = "The Azure Region in which all resources in this example should be provisioned"
}

variable "resource_group_name" {}

variable "vnet_subnet_id" {}

variable "mi_aks_cp_id" {}

variable "la_id" {}

variable "gateway_name" {}

variable "gateway_id" {}

variable "private_dns_zone_id" {}
