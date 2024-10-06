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

variable "admin-group-object-ids" {
  type    = string
  default = "d1553d93-3b9f-4d52-a28b-e4a4a27c114c"

}

variable "acrName" {
  type    = string
  default = "acrlzti5y"
}

variable "akvName" {
  type    = string
  default = "akvlzti5y"

}
