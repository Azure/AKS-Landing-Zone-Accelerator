locals {
  domain_name = {
    akv = "privatelink.vaultcore.azure.net",
    acr = "privatelink.azurecr.io",
    aks = "azurek8s.io"

  }
}

data "azurerm_client_config" "tenant" {}

data "azurerm_resource_group" "rg" {
  name = var.rgLzName
}

data "azurerm_virtual_network" "vnet-lz" {
  name                = var.vnetLzName
  resource_group_name = var.rgLzName
}

data "azurerm_subnet" "snet-spe" {
  name                 = "snet-spe"
  virtual_network_name = var.vnetLzName
  resource_group_name  = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszone-acr" {
  name                = local.domain_name.acr
  resource_group_name = var.rgLzName
}

data "azurerm_private_dns_zone" "dnszone-akv" {
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
  location                      = data.azurerm_resource_group.rg.location
  resource_group_name           = data.azurerm_resource_group.rg.name
  public_network_access_enabled = false
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [data.azurerm_private_dns_zone.dnszone-acr.id]
      subnet_resource_id            = data.azurerm_subnet.snet-spe.id
    }
  }
}

module "avm-res-keyvault-vault" {
  source                        = "Azure/avm-res-keyvault-vault/azurerm"
  version                       = "0.9.1"
  name                          = var.akvName
  location                      = data.azurerm_resource_group.rg.location
  resource_group_name           = data.azurerm_resource_group.rg.name
  tenant_id                     = data.azurerm_client_config.tenant.tenant_id
  public_network_access_enabled = false
  private_endpoints = {
    primary = {
      private_dns_zone_resource_ids = [data.azurerm_private_dns_zone.dnszone-akv.id]
      subnet_resource_id            = data.azurerm_subnet.snet-spe.id
    }
  }
}
