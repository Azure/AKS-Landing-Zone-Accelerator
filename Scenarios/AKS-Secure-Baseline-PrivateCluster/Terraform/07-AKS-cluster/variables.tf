#############
# VARIABLES #
#############
variable "private_dns_zone_name" {
  # update this in the .tfvars file
}

variable "dns_prefix" {
  # update this in the .tfvars file
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
  type      = string
  sensitive = true
}
