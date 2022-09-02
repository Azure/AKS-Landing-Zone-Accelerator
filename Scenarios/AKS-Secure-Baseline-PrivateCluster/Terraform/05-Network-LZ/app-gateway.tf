# Application Gateway and Supporting Infrastructure

#############
# LOCALS #
#############

/*
The following map enables the deployment of multiple application gateways, as example you can use to deploy two app gateways to support the the blue green deployment at AKS clusters level, instead if you need to deploy just one app gateway for sample and standard deployment then you you can configure a map with only one object.
locals {
  Map of the aure application gateway to deploy, it used to manage the standard deployment but also the blue green deployment.
  appgws = {
    "appgw_blue" = {
      prefix used to configure uniques names and parameter values
      name_prefix="blue"
      Boolean flag that enable or disable the deployment of the specific application gateway
      appgw_turn_on=true
    },
    "appgw_green" = {
      name_prefix="green"
      appgw_turn_on=false
    }
  }
}

*/

locals {
  appgws = {
    "appgw_blue" = {
      name_prefix="blue"
      appgw_turn_on=true
    },
    "appgw_green" = {
      name_prefix="green"
      appgw_turn_on=false
    }
  }
}

resource "azurerm_subnet" "appgw" {
  name                                             = "appgwSubnet"
  resource_group_name                              = azurerm_resource_group.spoke-rg.name
  virtual_network_name                             = azurerm_virtual_network.vnet.name
  address_prefixes                                 = ["10.1.1.0/24"]
  # enforce_private_link_endpoint_network_policies = false

}

module "appgw_nsgs" {
  source = "./modules/app_gw_nsg"

  resource_group_name = azurerm_resource_group.spoke-rg.name
  location            = azurerm_resource_group.spoke-rg.location
  nsg_name            = "${azurerm_virtual_network.vnet.name}-${azurerm_subnet.appgw.name}-nsg"

}

resource "azurerm_subnet_network_security_group_association" "appgwsubnet" {
  subnet_id                 = azurerm_subnet.appgw.id
  network_security_group_id = module.appgw_nsgs.appgw_nsg_id
}

# based on the structure of the appgws map are deployed multiple appplication gateway, usually this is used in the blue green scenario
resource "azurerm_public_ip" "appgw" {
  for_each = { for appgws in local.appgws : appgws.name_prefix => appgws if appgws.appgw_turn_on == true}
  name                = "appgw-pip-${each.value.name_prefix}"
  resource_group_name = azurerm_resource_group.spoke-rg.name
  location            = azurerm_resource_group.spoke-rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# based on the structure of the appgws map are deployed multiple appplication gateway, usually this is used in the blue green scenario
module "appgw" {
  source = "./modules/app_gw"
  depends_on = [
    module.appgw_nsgs
  ]
  for_each = { for appgws in local.appgws : appgws.name_prefix => appgws if appgws.appgw_turn_on == true}
  resource_group_name  = azurerm_resource_group.spoke-rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  location             = azurerm_resource_group.spoke-rg.location
  appgw_name           = "lzappgw-${each.value.name_prefix}"
  frontend_subnet      = azurerm_subnet.appgw.id
  appgw_pip            = azurerm_public_ip.appgw[each.value.name_prefix].id

}

# the app gateway name for each instance provisioned. If you are not using the blue green deployment then you can remove the for loop and use directly the attributes of the module module.appgw.
output "gateway_name" {
  value = { for appgws in module.appgw : appgws.gateway_name => appgws.gateway_name}
}

# the app gateway id for each instance provisioned. If you are not using the blue green deployment then you can remove the for loop and use directly the attributes of the module module.appgw.
output "gateway_id" {
  value = { for appgws in module.appgw : appgws.gateway_name => appgws.gateway_id}
}

# PIP IDs to permit the A Records registration in the DNS zone to invke the apps deployed on AKS. There is a PIP for each instance provisioned. If you are not using the blue green deployment then you can remove the for loop and use directly the attributes of the azurerm_public_ip.appgw resource.
output "azurerm_public_ip_ref" {
  value = { for pips in azurerm_public_ip.appgw : pips.name => pips.id}
}


