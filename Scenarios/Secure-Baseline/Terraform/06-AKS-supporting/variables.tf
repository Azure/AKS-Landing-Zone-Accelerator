#############
# VARIABLES #
#############

variable "access_key" {}   # Provide using a .tfvars file. 

variable "state_sa_name" {
    default = "tfstate-sa"   # Update this value
}

variable "container_name" {
    default = "akscs"    # Update this value
}

variable "prefix" {
  default = "akscs"
}

