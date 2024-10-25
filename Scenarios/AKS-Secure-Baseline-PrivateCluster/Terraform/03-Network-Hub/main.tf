# rg ensures we have unique CAF compliant names for our resources.
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["hub"]
}

# rg is required for resource modules
resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.rgHubName
}

locals {
  jumpbox_nsg_rules = {
    "rule01" = {
      name                       = "AllowRDPInBound"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "3389"
      direction                  = "Inbound"
      priority                   = 100
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
    rule02 = {
      name                       = "AllowSSHInBound"
      access                     = "Allow"
      destination_address_prefix = "*"
      destination_port_range     = "22"
      direction                  = "Inbound"
      priority                   = 200
      protocol                   = "Tcp"
      source_address_prefix      = "*"
      source_port_range          = "*"
    }
  }
}

module "avm-nsg-default" {
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version             = "0.2.0"
  name                = var.nsgHubDefaultName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

module "avm-nsg-vm" {
  source              = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version             = "0.2.0"
  name                = var.nsgVMName
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  security_rules      = local.jumpbox_nsg_rules

}

module "avm-res-network-virtualnetwork" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.2.4"
  # insert the 3 required variables here
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [var.hubVNETaddPrefixes]
  location            = azurerm_resource_group.rg.location
  name                = var.vnetHubName

  subnets = {
    default = {
      name             = "default"
      address_prefixes = [var.snetDefaultAddr]
      network_security_group = {
        id = module.avm-nsg-default.resource.id
      }
      route_table = {
        id = module.avm-res-network-routetable.resource_id
      }
    }
    AzureFirewallSubnet = {
      name             = "AzureFirewallSubnet"
      address_prefixes = [var.snetFirewallAddr]

    }
    AzureBastionSubnet = {
      name             = "AzureBastionSubnet"
      address_prefixes = [var.snetBastionAddr]
    }
    vmsubnet = {
      name             = "snet-vm"
      address_prefixes = [var.snetVMAddr]
      network_security_group = {
        id = module.avm-nsg-vm.resource.id
      }
      route_table = {
        id = module.avm-res-network-routetable.resource_id
      }
    }
  }
}

module "publicIpFW" {
  source              = "Azure/avm-res-network-publicipaddress/azurerm"
  version             = "0.1.2"
  resource_group_name = azurerm_resource_group.rg.name
  name                = "pip-azfw"
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availabilityZones
}

module "publicIpFWMgmt" {
  source              = "Azure/avm-res-network-publicipaddress/azurerm"
  version             = "0.1.2"
  resource_group_name = azurerm_resource_group.rg.name
  name                = "pip-azfw-management"
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availabilityZones
}

module "publicIpBastion" {
  source              = "Azure/avm-res-network-publicipaddress/azurerm"
  version             = "0.1.2"
  resource_group_name = azurerm_resource_group.rg.name
  name                = "pip-bastion"
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = var.availabilityZones
}

module "firewall_policy" {
  source              = "Azure/avm-res-network-firewallpolicy/azurerm"
  name                = "azureFirewallPolicy"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  firewall_policy_dns = {
    proxy_enabled = true
  }
}

module "rule_collection_group" {
  source                                                   = "Azure/avm-res-network-firewallpolicy/azurerm//modules/rule_collection_groups"
  firewall_policy_rule_collection_group_firewall_policy_id = module.firewall_policy.resource.id
  firewall_policy_rule_collection_group_name               = "NetworkRuleCollectionGroup"
  firewall_policy_rule_collection_group_priority           = 400

  firewall_policy_rule_collection_group_network_rule_collection = [
    {
      action   = "Allow"
      name     = "NetworkRuleCollection"
      priority = 400
      rule = [{
        name                  = "OutboundToInternet"
        description           = "Allow traffic outbound to the Internet"
        destination_addresses = ["*"]
        destination_ports     = ["443", "80"]
        source_addresses      = ["*"]
        protocols             = ["TCP"]
        },
        {
          name                  = "apiudp"
          rule_type             = "NetworkRule"
          protocols             = ["UDP"]
          source_addresses      = ["*"]
          destination_addresses = ["AzureCloud.*"]
          destination_ports     = ["1194"]
        },
        {
          name                  = "apitcp"
          rule_type             = "NetworkRule"
          protocols             = ["TCP"]
          source_addresses      = ["*"]
          destination_addresses = ["AzureCloud.*"]
          destination_ports     = ["9000"]
        },
        {
          name              = "time"
          rule_type         = "NetworkRule"
          protocols         = ["UDP"]
          source_addresses  = ["*"]
          destination_fqdns = ["ntp.ubuntu.com"]
          destination_ports = ["123"]
        },
        {
          name              = "ghcr"
          rule_type         = "NetworkRule"
          protocols         = ["TCP"]
          source_addresses  = ["*"]
          destination_fqdns = ["ghcr.io", "pkg-containers.githubusercontent.com"]
          destination_ports = ["443"]
        },
        {
          name              = "docker"
          rule_type         = "NetworkRule"
          protocols         = ["TCP"]
          source_addresses  = ["*"]
          destination_fqdns = ["docker.io", "registry-1.docker.io", "production.cloudflare.docker.com"]
          destination_ports = ["443"]
        }
      ]
    }
  ]
  firewall_policy_rule_collection_group_application_rule_collection = [
    {
      action   = "Allow"
      name     = "ApplicationRuleCollection"
      priority = 600
      rule = [
        {
          name             = "AllowAll"
          description      = "Allow traffic to Microsoft.com"
          source_addresses = ["10.1.0.0/16"]
          protocols = [
            {
              port = 443
              type = "Https"
            }
          ]
          destination_fqdns = ["microsoft.com"]
        },
        {
          name             = "egress"
          description      = "AKS egress Traffic"
          source_addresses = ["10.1.1.0/24"]
          protocols = [
            {
              port = 443
              type = "Https"
            }
          ]
          destination_fqdns = ["*.azmk8s.io",
            "aksrepos.azurecr.io",
            "*.blob.core.windows.net",
            "*.cdn.mscr.io",
            "*.opinsights.azure.com",
          "*.monitoring.azure.com"]
        },
        {
          name             = "Registries"
          description      = "ACR Traffic"
          source_addresses = ["10.1.1.0/24"]
          protocols = [
            {
              port = 443
              type = "Https"
            }
          ]
          destination_fqdns = ["*.azurecr.io",
            "*.gcr.io",
            "*.docker.io",
            "quay.io",
            "*.quay.io",
            "*.cloudfront.net",
          "production.cloudflare.docker.com"]
        },
        {
          name             = "aksfwar"
          description      = "AKS Service Tag"
          source_addresses = ["10.1.1.0/24"]
          protocols = [
            { port = 80
              type = "Http"
            },
            { port = 443
              type = "Https"
          }]
          destination_fqdn_tags = ["AzureKubernetesService"]
        }
      ]
    }
  ]
}

module "avm-res-network-azurefirewall" {
  source              = "Azure/avm-res-network-azurefirewall/azurerm"
  version             = "0.2.0"
  resource_group_name = azurerm_resource_group.rg.name
  name                = "azureFirewall"
  location            = azurerm_resource_group.rg.location
  firewall_sku_name   = "AZFW_VNet"
  firewall_sku_tier   = "Standard"
  firewall_zones      = var.availabilityZones
  firewall_policy_id  = module.firewall_policy.resource_id
  firewall_ip_configuration = [
    {
      name                 = "ipconfig1"
      subnet_id            = module.avm-res-network-virtualnetwork.subnets["AzureFirewallSubnet"].resource.id
      public_ip_address_id = module.publicIpFW.public_ip_id
    }
  ]

}

module "azure_bastion" {
  source = "Azure/avm-res-network-bastionhost/azurerm"

  name                = "bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  copy_paste_enabled  = true
  file_copy_enabled   = false
  sku                 = "Standard"
  ip_configuration = {
    name                 = "bastion-ipconfig"
    subnet_id            = module.avm-res-network-virtualnetwork.subnets["AzureBastionSubnet"].resource_id
    public_ip_address_id = module.publicIpBastion.public_ip_id
  }
  ip_connect_enabled     = true
  scale_units            = 4
  shareable_link_enabled = true
  tunneling_enabled      = true
  kerberos_enabled       = false
}

module "avm-res-network-routetable" {
  source              = "Azure/avm-res-network-routetable/azurerm"
  version             = "0.2.0"
  resource_group_name = azurerm_resource_group.rg.name
  name                = var.rtHubName
  location            = azurerm_resource_group.rg.location

  routes = {
    route1 = {
      name                   = "vm-to-internet"
      address_prefix         = var.routeAddr
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = module.avm-res-network-azurefirewall.resource.ip_configuration[0].private_ip_address
    }
  }
  depends_on = [azurerm_resource_group.rg]
}
