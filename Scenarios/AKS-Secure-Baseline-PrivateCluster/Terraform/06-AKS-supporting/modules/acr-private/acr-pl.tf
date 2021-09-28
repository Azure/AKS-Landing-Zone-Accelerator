resource "azurerm_container_registry" "acr" {
  name                = var.acrname
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Premium"
  public_network_access_enabled = false
  admin_enabled = true

}

resource "azurerm_private_endpoint" "acr-endpoint" {
  name                = "${var.acrname}-to_aks"
  location            = var.location
  resource_group_name   = var.resource_group_name
  subnet_id           = var.aks_sub_id

  private_service_connection {
    name                = "${var.acrname}-privateserviceconnection"
    private_connection_resource_id = azurerm_container_registry.acr.id
    subresource_names = ["registry"]
    is_manual_connection              = false

  }

  private_dns_zone_group {
    name = "acr-endpoint-zone"
    private_dns_zone_ids = [var.private_zone_id]
  }
}

output "acr_id" {
  value = azurerm_container_registry.acr.id
}

output "custom_dns_configs" {
    value = azurerm_private_endpoint.acr-endpoint.custom_dns_configs
}

# Variables

variable "acrname" {

}
variable "resource_group_name" {
    
}
variable "location" {
    
}

variable "aks_sub_id" {
  
}

variable "private_zone_id" {

}


