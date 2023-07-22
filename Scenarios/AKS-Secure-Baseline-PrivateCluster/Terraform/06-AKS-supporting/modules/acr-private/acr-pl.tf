resource "azurerm_container_registry" "acr" {
  name                          = replace(var.caf_basename.azurerm_container_registry, var.caf_instance, "${var.random_instance}")
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = "Premium"
  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "acr-endpoint" {
  name                = replace(var.caf_basename.azurerm_private_endpoint, "pe", "acrpe")
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.priv_sub_id

  private_service_connection {
    name                           = replace(azurerm_container_registry.acr.name, "acr", "acrpsc")
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = replace(azurerm_container_registry.acr.name, "acr", "acrpdns")
    private_dns_zone_ids = [var.private_zone_id]
  }
}
#############
## OUTPUTS ##
#############
# These outputs are used by later deployments
output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}
output "custom_dns_configs" {
  value = azurerm_private_endpoint.acr-endpoint.custom_dns_configs
}
