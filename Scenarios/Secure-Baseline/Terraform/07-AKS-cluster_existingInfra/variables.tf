#############
# VARIABLES #
#############

variable "prefix" {}

variable "state_sa_name" {}

variable "container_name" {}

variable "access_key" {}

variable "net_plugin" {
    default = "azure"  #Options are "azure" or "kubenet"
}





