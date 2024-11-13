variable "location" {
  type    = string
  default = "eastus"
}

variable "rgLzName" {
  type    = string
  default = "AksTerra-AVM-LZ-RG"
}

variable "vnetLzName" {
  type    = string
  default = "vnet-lz"
}

variable "rgHubName" {
  type    = string
  default = "AksTerra-AVM-Hub-RG"
}

variable "vnetHubName" {
  type    = string
  default = "vnet-hub"
}

variable "acrName" {
  type    = string
  default = "acrlzti5y24"
}

variable "akvName" {
  type    = string
  default = "akvlzti5y24"
}

variable "deployingAllInOne" {
  type    = bool
  default = false
}

variable "speSubnetId" {
  type = string
  default = ""
}

variable "dnszoneAkvId" {
  type = string
  default = ""
}

variable "dnszoneAcrId" {
  type = string
  default = ""
}