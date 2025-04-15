variable "location" {
  type    = string
  default = "eastus"
}

variable "rgLzName" {
  type    = string
  default = "AksTerra-AVM-LZ-RG"
}

variable "rgHubName" {
  type    = string
  default = "AksTerra-AVM-Hub-RG"
}

variable "vnetHubName" {
  type    = string
  default = "vnet-hub"
}

variable "vnetHubId" {
  type        = string
  default     = ""
  description = "Should be value from output of 03-Network-Hub. Used only when deploying All-in-One scenario."
}

variable "firewallPrivateIp" {
  type        = string
  default     = ""
  description = "Should be value from output of 03-Network-Hub. Used only when deploying All-in-One scenario."
}

variable "deployingAllInOne" {
  type    = bool
  default = false
}

variable "vnetLzName" {
  type    = string
  default = "vnet-lz"
}

variable "rtLzName" {
  type    = string
  default = "rt-lz-table"
}

variable "nsgLzDefaultName" {
  type    = string
  default = "nsg-default"
}

variable "nsgAppGWName" {
  type    = string
  default = "nsg-appgw"
}

variable "spokeVNETaddPrefixes" {
  type    = string
  default = "10.1.0.0/16"
}

variable "snetDefaultAddr" {
  type    = string
  default = "10.1.0.0/24"
}

variable "snetAksAddr" {
  type    = string
  default = "10.1.1.0/26"
}

variable "snetAppGWAddr" {
  type    = string
  default = "10.1.2.0/27"
}

variable "snetVMAddr" {
  type    = string
  default = "10.1.3.0/27"
}

variable "snetServicePeAddr" {
  type    = string
  default = "10.1.4.0/27"
}

variable "routeAddr" {
  type    = string
  default = "0.0.0.0/0"
}
