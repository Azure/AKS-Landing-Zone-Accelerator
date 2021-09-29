resource "azurerm_key_vault" "key-vault" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    bypass = "AzureServices"
    default_action = "Deny"
  }


}

resource "azurerm_private_endpoint" "kv-endpoint" {
  name                = "${var.name}-endpoint"
  location            = var.location
  resource_group_name   = var.resource_group_name
  subnet_id           = var.dest_sub_id

  private_service_connection {
    name                              = "${var.name}-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.key-vault.id
    subresource_names = ["vault"]
    is_manual_connection              = false

  }

  private_dns_zone_group {
    name = "kv-endpoint-zone"
    private_dns_zone_ids = [var.private_zone_id]
  }

}

output "kv_id" {
    value = azurerm_key_vault.key-vault.id
}

output "key_vault_url" {
  value       = azurerm_key_vault.key-vault.vault_uri 
}


# Variables

variable "zone_resource_group_name" {

}

variable "dest_sub_id" {

}


variable "private_zone_id" {

}

variable "private_zone_name" {

}

variable "vnet_id" {

}



