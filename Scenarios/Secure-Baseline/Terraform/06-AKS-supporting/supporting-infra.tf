resource "random_integer" "deployment" {
  min = 10000
  max = 99999
}

# Deploy Azure Container Registry

module "create_acr" {
  source = "./modules/acr-private"

  acrname             = "acr${random_integer.deployment.result}"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  aks_sub_id          = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  private_zone_id     = data.terraform_remote_state.existing-lz.outputs.acr_private_zone_id

}

# Deploy Azure Key Vault

module "create_kv" {
  source                   = "./modules/kv-private"
  
  name                     = "kv${random_integer.deployment.result}-${var.prefix}"
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location            = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  tenant_id                = data.azurerm_client_config.current.tenant_id
  vnet_id                  = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
  dest_sub_id              = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  private_zone_id          = data.terraform_remote_state.existing-lz.outputs.kv_private_zone_id
  private_zone_name        = data.terraform_remote_state.existing-lz.outputs.kv_private_zone_name
  zone_resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name

}
