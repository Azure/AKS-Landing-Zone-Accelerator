#############
# VARIABLES #
#############
variable "location" {

  default = "eastus"
}

variable "tags" {
  type = map(string)

  default = {
    project = "spoke-lz"
  }
}

variable "lz_prefix" {
  default = "lz"
}

variable "resource_group_name" {
  default = "jose-aksdeps-rg"
}

variable "storage_account_name" {
  default = "tfstatejose23"
}

variable "container_name" {
  default = "tfstate"
}

variable "access_key" {
  sensitive = true
  type      = string
}
