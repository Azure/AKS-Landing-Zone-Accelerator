#############
# VARIABLES #
#############

variable "access_key" {}   # Provide using a .tfvars file. 

variable "state_sa_name" {
    default = "tfstatestorejkc"   # Update this value
}

variable "container_name" {
    default = "escsjkc"    # Update this value
}

variable "prefix" {
  default = "jkc"
}

