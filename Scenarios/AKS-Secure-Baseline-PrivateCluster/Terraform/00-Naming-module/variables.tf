variable "workload" {
  type        = string
  description = "Workload acronyms/short names (max 4 chars)"
  validation {
    condition = (
      can(regex("^[a-zA-Z0-9]{1,4}$", var.workload))
    )
    error_message = "The workload does not follow CAF naming structure."
  }
}

variable "environment" {
  type        = string
  description = "Environment association (max 3 chars)"
  validation {
    condition = (
      can(regex("^[a-zA-Z0-9]{1,3}$", var.environment))
    )
    error_message = "The stage does not follow CAF naming structure."
  }
}

variable "region" {
  type        = string
  description = "The Azure region where the resource is deployed (max 3 chars)"
  validation {
    condition = (
      can(regex("^[a-zA-Z0-9]{1,3}$", var.region))
    )
    error_message = "The region does not follow CAF naming structure."
  }
}

variable "instance" {
  type        = string
  description = "Instance number, if workload includes/requires multiple resources of the same type (max 3 int)"
  validation {
    condition = (
      can(regex("^[0-9]{3}$", var.instance))
    )
    error_message = "The Instance does not follow CAF naming structure. 0 to 3 digits are allowed."
  }
}
