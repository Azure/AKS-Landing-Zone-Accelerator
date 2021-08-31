#############
# VARIABLES #
#############

variable "tags" {
  type = map(string)

  default = {
    project = "spoke-lz"
  }
}

variable "lz_prefix" {
  default = "escs-lz01"
}


# Used to retrieve outputs from other state files.
# The "access_key" variable is sensitive and should be passed using
# a .TFVARS file or other secure method. 

variable "state_sa_name" {
    default = "tfstate"   # Update this value to match provider.tf
}

variable "container_name" {
    default = "akscs"     # Update this value to match provider.tf
}

# Storage Account Access Key
variable "access_key" {}



