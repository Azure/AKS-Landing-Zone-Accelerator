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
  resource_group_name      = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
  location                 = data.terraform_remote_state.existing-lz.outputs.lz_rg_location
  tenant_id                = data.azurerm_client_config.current.tenant_id
  vnet_id                  = data.terraform_remote_state.existing-lz.outputs.lz_vnet_id
  dest_sub_id              = data.terraform_remote_state.existing-lz.outputs.aks_subnet_id
  private_zone_id          = data.terraform_remote_state.existing-lz.outputs.kv_private_zone_id
  private_zone_name        = data.terraform_remote_state.existing-lz.outputs.kv_private_zone_name
  zone_resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name

}

# Deploy Public DNS to register application domains hosted in AKS. If you are not planning to use the blue green deployment, then you don't need to deploy the public DNS Zone and you can skip this leaving empty the variable public_domain.
resource "azurerm_dns_zone" "public-dns-apps" {
  count = var.public_domain != "" ? 1 : 0
  name                = var.public_domain
  resource_group_name = data.terraform_remote_state.existing-lz.outputs.lz_rg_name
}

# DNS Zone name to map A records. This is empty if the public DNS Zone is not deployed.
output "public_dns_zone_apps_name" {
  value = one (azurerm_dns_zone.public-dns-apps[*].name)
}

# DNS Zone ID to reference in other terraform state and/or resources/modules. This is empty if the public DNS Zone is not deployed.
output "public_dns_zone_apps_id" {
  value = one(azurerm_dns_zone.public-dns-apps[*].id)
}