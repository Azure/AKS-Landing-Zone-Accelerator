# Key Vault Access for Current User

resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = module.create_kv.kv_id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "get", "list", "set", "delete"
  ]
}

# Azure KeyVault secret for MongoDB

resource "azurerm_key_vault_secret" "mongodb" {
  name         = "MongoDB"
  value        = var.mongodb_secret
  key_vault_id = module.create_kv.kv_id
  depends_on = [
    azurerm_key_vault_access_policy.current_user
  ]
}

variable "mongodb_secret" {}



