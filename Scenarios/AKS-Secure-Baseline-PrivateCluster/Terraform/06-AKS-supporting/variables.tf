#############
# VARIABLES #
#############

variable "prefix" {}

variable "access_key" {}   # Provide using a .tfvars file.

variable "state_sa_name" {}

variable "container_name" {}

# The Public Domain for the public dns zone, that is used to register the hostnames assigned to the workloads hosted in AKS; if empty the dns zone not provisioned.
variable "public_domain" {
    description = "The Public Domain for the public dns zone, that is used to register the hostnames assigned to the workloads hosted in AKS; if empty the dns zone not provisioned."
    default = ""
}