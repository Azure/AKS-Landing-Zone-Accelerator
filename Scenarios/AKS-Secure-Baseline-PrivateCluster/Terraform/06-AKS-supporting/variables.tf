#############
# VARIABLES #
#############
variable "prefix" {
  default = "aks"
}

# The Public Domain for the public dns zone, that is used to register the hostnames assigned to the workloads hosted in AKS; if empty the dns zone not provisioned.
variable "public_domain" {
  description = "The Public Domain for the public dns zone, that is used to register the hostnames assigned to the workloads hosted in AKS; if empty the dns zone not provisioned."
  default     = ""
}
## Terraform backend state variables ##

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
