variable "rgLzName" {
  type    = string
  default = "AksTerra-AVM-LZ-RG"
}

variable "rgHubName" {
  type    = string
  default = "AksTerra-AVM-Hub-RG"
}

variable "location" {
  type    = string
  default = "eastus"
}

variable "vnetLzName" {
  type    = string
  default = "vnet-lz"
}

variable "vnetHubName" {
  type    = string
  default = "vnet-hub"
}

variable "adminGroupObjectIds" {
  type    = string
  default = " "
}

variable "acrName" {
  type    = string
  default = "acrlzti5y"
}

variable "akvName" {
  type    = string
  default = "akvlzti5y"
}
