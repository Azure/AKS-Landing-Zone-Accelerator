#############
# VARIABLES #
#############

variable "prefix" {}

variable "state_sa_name" {}

variable "container_name" {}

variable "access_key" {}

variable "private_dns_zone_name" {
default =  "privatelink.eastus.azmk8s.io"
}