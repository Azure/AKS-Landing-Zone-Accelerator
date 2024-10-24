variable "location" {
  type    = string
  default = "eastus"
}

variable "rgHubName" {
  type    = string
  default = "AksTerra-AVM-Hub-RG"
}

variable "nsgDefaultName" {
  type    = string
  default = "nsg-default"
}

variable "nsgVMName" {
  type    = string
  default = "nsg-vm"
}
variable "hubVNETaddPrefixes" {
  type    = string
  default = "10.0.0.0/16"
}

variable "snetDefaultAddr" {
  type    = string
  default = "10.0.0.0/24"
}

variable "snetFirewallAddr" {
  type    = string
  default = "10.0.1.0/26"
}

variable "snetBastionAddr" {
  type    = string
  default = "10.0.2.0/27"
}

variable "snetVMAddr" {
  type    = string
  default = "10.0.3.0/27"
}

variable "routeAddr" {
  type    = string
  default = "0.0.0.0/0"
}

variable "vnetHubName" {
  type    = string
  default = "vnet-hub"
}

variable "availabilityZones" {
  type    = list(string)
  default = ["1", "2", "3"]
}

variable "rtName" {
  type    = string
  default = "rt-hub-table"
}
