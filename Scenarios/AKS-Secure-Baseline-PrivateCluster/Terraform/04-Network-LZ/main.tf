locals {
  vnetHubId         = var.deployingAllInOne == true ? var.vnetHubId : data.azurerm_virtual_network.vnethub.0.id
  firewallPrivateIp = var.deployingAllInOne == true ? var.firewallPrivateIp : data.azurerm_firewall.firewall.0.ip_configuration.0.private_ip_address
}
# locals {
#   vnetHubId         = var.vnetHubId != "" ? var.vnetHubId : data.azurerm_virtual_network.vnethub.0.id
#   firewallPrivateIp = var.firewallPrivateIp != "" ? var.firewallPrivateIp : data.azurerm_firewall.firewall.0.ip_configuration.0.private_ip_address
# }
# locals {
#   vnetHubId = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.rgHubName}/providers/Microsoft.Network/virtualNetworks/${var.vnetHubName}"
# }
# data "azurerm_subscription" "current" {}

data "azurerm_virtual_network" "vnethub" {
  count               = var.deployingAllInOne == true ? 0 : 1
  # count               = var.vnetHubId == "" ? 1 : 0
  name                = var.vnetHubName
  resource_group_name = var.rgHubName
}

data "azurerm_firewall" "firewall" {
  count               = var.deployingAllInOne == true ? 0 : 1
  # count               = var.firewallPrivateIp == "" ? 1 : 0
  name                = "azureFirewall"
  resource_group_name = var.rgHubName
}

# rg ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["lz"]
}

# rg is required for resource modules
resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.rgLzName
}

module "avm-res-network-routetable" {
  source              = "Azure/avm-res-network-routetable/azurerm"
  version             = "0.2.0"
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.rtLzName
  location            = azurerm_resource_group.rg.location
  depends_on          = [azurerm_resource_group.rg]

  routes = {
    route1 = {
      name                   = "aks-to-internet"
      address_prefix         = var.routeAddr
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.firewallPrivateIp
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
    "rule03" = {
      name                       = "Allow80InBound"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_ranges    = ["80"]
      direction                  = "Inbound"
      priority                   = 300
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
  }
}

module "avm-nsg-default" {
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version             = "0.2.0"
  name                = var.nsgLzDefaultName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

module "avm-nsg-appgw" {
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version             = "0.2.0"
  name                = var.nsgAppGWName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  security_rules      = local.appgw_nsg_rules
}

module "avm-res-network-vnet" {
  source              = "Azure/avm-res-network-virtualnetwork/azurerm"
  version             = "0.2.4"
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.spokeVNETaddPrefixes]
  location            = azurerm_resource_group.rg.location
  name                = var.vnetLzName
  dns_servers = {
    dns_servers = [local.firewallPrivateIp]
  }

  subnets = {
    default = {
      name             = "default"
      address_prefixes = [var.snetDefaultAddr]
      network_security_group = {
        id = module.avm-nsg-default.resource.id
      }
      route_table = {
        id = module.avm-res-network-routetable.resource.id
      }
    }
  }
}
module "avm-res-network-vnet-aks-subnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.4.0"
  name    = "snet-aks"
  virtual_network = {
    resource_id = module.avm-res-network-vnet.resource.id
  }
  address_prefixes = [var.snetAksAddr]
  route_table = {
    id = module.avm-res-network-routetable.resource.id
  }
  network_security_group = {
    id = module.avm-nsg-default.resource.id
  }

  depends_on = [module.avm-res-network-vnet.resource]
}

module "avm-res-network-vnet-appgw-subnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.4.0"
  name    = "snet-appgw"
  virtual_network = {
    resource_id = module.avm-res-network-vnet.resource.id
  }
  address_prefixes = [var.snetAppGWAddr]
  network_security_group = {
    id = module.avm-nsg-appgw.resource.id
  }

  depends_on = [module.avm-res-network-vnet.resource]
}

module "avm-res-network-vnet-vm-subnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.4.0"
  name    = "snet-vm"
  virtual_network = {
    resource_id = module.avm-res-network-vnet.resource.id
  }
  address_prefixes = [var.snetVMAddr]
  route_table = {
    id = module.avm-res-network-routetable.resource.id
  }
  network_security_group = {
    id = module.avm-nsg-default.resource.id
  }

  depends_on = [module.avm-res-network-vnet.resource]
}

module "avm-res-network-vnet-spe-subnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/subnet"
  version = "0.4.0"
  name    = "snet-spe"
  virtual_network = {
    resource_id = module.avm-res-network-vnet.resource.id
  }
  address_prefixes = [var.snetServicePeAddr]
  route_table = {
    id = module.avm-res-network-routetable.resource.id
  }
  network_security_group = {
    id = module.avm-nsg-default.resource.id
  }

  depends_on = [module.avm-res-network-vnet.resource]
}

module "avm-res-network-vnet-peering" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm//modules/peering"
  version = "0.2.4"
  virtual_network = {
    resource_id = module.avm-res-network-vnet.resource.id
  }
  remote_virtual_network = {
    resource_id = local.vnetHubId # data.azurerm_virtual_network.vnethub.id
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

locals {
  domain_name = {
    akv               = "privatelink.vaultcore.azure.net",
    acr               = "privatelink.azurecr.io",
    aks               = "azmk8s.io"
    contoso           = "private.contoso.com"
    AzureUSGovernment = ".cx.aks.containerservice.azure.us"
    AzureChinaCloud   = ".cx.prod.service.azk8s.cn"
    AzureGermanCloud  = "" //TODO: what is the correct value here?
  }
}

module "avm-res-network-privatednszone-aks" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.1.2"
  resource_group_name = azurerm_resource_group.rg.name
  domain_name         = "privatelink.${var.location}.${local.domain_name.aks}"
  virtual_network_links = {
    vnetlink = {
      vnetlinkname     = "vlink-ak"
      vnetid           = local.vnetHubId # data.azurerm_virtual_network.vnethub.id
      autoregistration = false
  } }
}

module "avm-res-network-privatednszone-akv" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.1.2"
  resource_group_name = azurerm_resource_group.rg.name
  domain_name         = local.domain_name.akv
  virtual_network_links = {
    vnetlink = {
      vnetlinkname     = "vlink-akv"
      vnetid           = local.vnetHubId # data.azurerm_virtual_network.vnethub.id
      autoregistration = false
  } }

}

module "avm-res-network-privatednszone-acr" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.1.2"
  resource_group_name = azurerm_resource_group.rg.name
  domain_name         = local.domain_name.acr
  virtual_network_links = {
    vnetlink = {
      vnetlinkname     = "vlink-acr"
      vnetid           = local.vnetHubId # data.azurerm_virtual_network.vnethub.id
      autoregistration = false
  } }
}

module "avm-res-network-privatednszone-contoso" {
  source              = "Azure/avm-res-network-privatednszone/azurerm"
  version             = "0.1.2"
  resource_group_name = azurerm_resource_group.rg.name
  domain_name         = local.domain_name.contoso
  virtual_network_links = {
    vnetlink = {
      vnetlinkname     = "vlink-contoso"
      vnetid           = local.vnetHubId # data.azurerm_virtual_network.vnethub.id
      autoregistration = false
  } }
}

module "avm-res-network-appgw" {
  source              = "Azure/avm-res-network-applicationgateway/azurerm"
  version             = "0.1.1"
  resource_group_name = azurerm_resource_group.rg.name
  name                = "appgw"
  location            = azurerm_resource_group.rg.location
  public_ip_name      = "pip-appgw"
  vnet_name           = module.avm-res-network-vnet.resource.name
  subnet_name_backend = module.avm-res-network-vnet-appgw-subnet.resource.name
  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 0
  }

  autoscale_configuration = {
    min_capacity = 1
    max_capacity = 2
  }

  frontend_ports = {
    frontend-port-80 = {
      name = "frontend-port-80"
      port = 80
    }
  }

  probe_configurations = {
    appGatewayProbe = {
      name                = "appGatewayProbe"
      protocol            = "Http"
      path                = "/healthz"
      host                = local.domain_name.contoso
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    }
  }

  backend_address_pools = {
    appGatewayBackendPool = {
      name = "appGatewayBackendPool"
      # ip_addresses = ["10.0.1.6"]
      fqdns = [local.domain_name.contoso]
    }
  }

  backend_http_settings = {

    appGatewayBackendHttpSettings = {
      name                                = "appGatewayBackendHttpSettings"
      cookie_based_affinity               = "Disabled"
      path                                = "/"
      enable_https                        = false
      request_timeout                     = 30
      pick_host_name_from_backend_address = true
      probe_name                          = "appGatewayProbe"
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    }

  }
  http_listeners = {
    appGatewayHttpListener = {
      name               = "appGatewayHttpListener"
      host_name          = null
      frontend_port_name = "frontend-port-80"
    }

  }
  request_routing_rules = {
    routing-rule-1 = {
      name                       = "rule-1"
      rule_type                  = "Basic"
      http_listener_name         = "appGatewayHttpListener"
      backend_address_pool_name  = "appGatewayBackendPool"
      backend_http_settings_name = "appGatewayBackendHttpSettings"
      priority                   = 100
    }

  }
  zones = ["1", "2", "3"]

  depends_on = [module.avm-res-network-vnet-appgw-subnet.resource]
}
