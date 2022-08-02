resource "azurerm_dns_a_record" "app_record" {
  for_each = var.arecords_apps_map
  name                = each.value.record_name
  zone_name           = data.terraform_remote_state.aks-support.outputs.public_dns_zone_apps_name
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  ttl                 = 300
  target_resource_id  = data.terraform_remote_state.existing-lz.outputs.azurerm_public_ip_ref["appgw-pip-${each.value.aks_active_prefix}"]
}