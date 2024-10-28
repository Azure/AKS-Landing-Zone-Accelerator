locals {
  domain_name = {
    akv = "privatelink.vaultcore.azure.net",
    acr = "privatelink.azurecr.io",
    aks = "azurek8s.io"
  }

  speSubnetId  = var.deployingAllInOne == true ? var.speSubnetId : data.azurerm_subnet.snet-spe.0.id
  dnszoneAkvId = var.deployingAllInOne == true ? var.dnszoneAkvId : data.azurerm_private_dns_zone.dnszone-akv.0.id
  dnszoneAcrId = var.deployingAllInOne == true ? var.dnszoneAcrId : data.azurerm_private_dns_zone.dnszone-acr.0.id
}

data "azurerm_client_config" "tenant" {}

# data "azurerm_resource_group" "rg" {
#   count = var.deployingAllInOne == true ? 0 : 1
#   name  = var.rgLzName
# }

# data "azurerm_virtual_network" "vnet-lz" {
#   count               = var.deployingAllInOne == true ? 0 : 1
#   name                = var.vnetLzName
#   resource_group_name = var.rgLzName
# }

data "azurerm_subnet" "snet-spe" {
  count                = var.deployingAllInOne == true ? 0 : 1
  name                 = "snet-spe"
  virtual_network_name = var.vnetLzName
  resource_group_name  = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszone-acr" {
  count               = var.deployingAllInOne == true ? 0 : 1
  name                = local.domain_name.acr
  resource_group_name = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszone-akv" {
  count               = var.deployingAllInOne == true ? 0 : 1
  name                = local.domain_name.akv
  resource_group_name = var.rgLzName
}

module "naming" {
  source  = "Azure/naming/azurerm"
  version = "~> 0.3"
  suffix  = ["lz"]
}

module "avm-res-containerregistry-registry" {
  source                        = "Azure/avm-res-containerregistry-registry/azurerm"
  version                       = "0.3.1"
  name                          = var.acrName
  location                      = var.location
  resource_group_name           = var.rgLzName
  public_network_access_enabled = false
  network_rule_bypass_option    = "AzureServices"

  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [local.dnszoneAcrId]
      subnet_resource_id            = local.speSubnetId
    }
  }
}

module "avm-res-keyvault-vault" {
  source                        = "Azure/avm-res-keyvault-vault/azurerm"
  version                       = "0.9.1"
  name                          = var.akvName
  location                      = var.location
  resource_group_name           = var.rgLzName
  tenant_id                     = data.azurerm_client_config.tenant.tenant_id
  public_network_access_enabled = false
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [local.dnszoneAkvId]
      subnet_resource_id            = local.speSubnetId
    }
  }
}
