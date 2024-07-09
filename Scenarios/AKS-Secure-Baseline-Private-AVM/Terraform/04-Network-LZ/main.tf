locals {
  AzureCloud        = ".azmk8s.io"
  AzureUSGovernment = ".cx.aks.containerservice.azure.us"
  AzureChinaCloud   = ".cx.prod.service.azk8s.cn"
  AzureGermanCloud  = "" //TODO: what is the correct value here?
}


data "azurerm_virtual_network" "vnethub" {
  name                = var.vnetHubName
  resource_group_name = var.rgHubName
}

data "azurerm_firewall" "firewall" {
  name                = "azureFirewall"
  resource_group_name = var.rgHubName

}

# This ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["lz"]
}

# This is required for resource modules
resource "azurerm_resource_group" "this" {
  location = "eastus" ##module.regions.regions[random_integer.region_index.result].name
  name     = var.rgLzName
}

module "avm-res-network-routetable" {
  source              = "Azure/avm-res-network-routetable/azurerm"
  version             = "0.2.0"
  resource_group_name = azurerm_resource_group.this.name
  name                = var.rtName
  location            = azurerm_resource_group.this.location

  routes = {
    route1 = {
      name                   = "aks-to-internet"
      address_prefix         = var.routeAddr
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = data.azurerm_firewall.firewall.ip_configuration[0].private_ip_address
    }
  }
}

locals {
  appgw_nsg_rules = {
    "rule01" = {
      name                       = "Allow443InBound"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "443"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
    "rule02" = {
      name                       = "AllowControlPlaneV2SKU"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_ranges    = ["65200-65535"]
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_address_prefix      = "GatewayManager"
      source_port_range          = "*"
    }
  }
}

module "avm-nsg-default" {
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version             = "0.2.0"
  name                = var.nsgDefaultName
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

module "avm-nsg-appgw" {
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version             = "0.2.0"
  name                = var.nsgAppGWName
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  security_rules      = local.appgw_nsg_rules
}

module "avm-res-network-virtualnetwork" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.2.4"
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.spokeVNETaddPrefixes]
  location            = azurerm_resource_group.this.location
  name                = var.vnetHubName

  subnets = {
    default = {
      name             = "default"
      address_prefixes = [var.snetDefaultAddr]
      network_security_group = {
        id = module.avm-nsg-default.resource.id
      }
    }
    AKS = {
      name             = "snet-aks"
      address_prefixes = [var.snetAksAddr]
      route_table = {
        id = module.avm-res-network-routetable.resource.id
      }

    }
    AppGWSubnet = {
      name             = "snet-appgw"
      address_prefixes = [var.snetAppGWAddr]
      network_security_group = {
        id = module.avm-nsg-appgw.resource.id
      }
    }
  }
}

module "avm-res-network-virtualnetwork_peering" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "0.2.4"
  virtual_network = {
    resource_id = module.avm-res-network-virtualnetwork.resource.id
  }
  remote_virtual_network = {
    resource_id = data.azurerm_virtual_network.vnethub.id
  }
  name                                 = "local-to-remote"
  allow_forwarded_traffic              = true
  allow_gateway_transit                = true
  allow_virtual_network_access         = true
  use_remote_gateways                  = false
  create_reverse_peering               = true
  reverse_name                         = "remote-to-local"
  reverse_allow_forwarded_traffic      = false
  reverse_allow_gateway_transit        = false
  reverse_allow_virtual_network_access = true
  reverse_use_remote_gateways          = false
}
