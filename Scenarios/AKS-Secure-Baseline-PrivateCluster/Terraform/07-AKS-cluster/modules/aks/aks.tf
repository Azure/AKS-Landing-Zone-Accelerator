# Creates cluster with default linux node pool

resource "azurerm_kubernetes_cluster" "akscluster" {
  lifecycle {
   ignore_changes = [
     default_node_pool[0].node_count
   ]
  }

  name                                = var.prefix
  dns_prefix                          = var.prefix
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  kubernetes_version                  = "1.23.5"
  private_cluster_enabled             = true
  private_dns_zone_id                 = var.private_dns_zone_id
  azure_policy_enabled                = true
  private_cluster_public_fqdn_enabled = false

  ingress_application_gateway {
    gateway_id = var.gateway_id
  }

  oms_agent {
    log_analytics_workspace_id = var.la_id
  }

  default_node_pool {
    name            = "defaultpool"
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
    node_count      = 3
    vnet_subnet_id  = var.vnet_subnet_id
  }

  network_profile {
    network_plugin     = var.network_plugin
    # network_policy   = "azure"
    outbound_type      = "userDefinedRouting"
    dns_service_ip     = "192.168.100.10"
    service_cidr       = "192.168.100.0/24"
    docker_bridge_cidr = "172.16.1.1/30"
    pod_cidr           = var.pod_cidr

  }

  role_based_access_control_enabled = true

  azure_active_directory_role_based_access_control {
      managed            = true
    //  admin_group_object_ids = talk to Ayo about this one, this arg could reduce code other places possibly 
      azure_rbac_enabled = true
    }

  identity {
    type         = "UserAssigned"
    identity_ids = [var.mi_aks_cp_id]
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }
}

output "aks_id" {
  value = azurerm_kubernetes_cluster.akscluster.id
}

output "node_pool_rg" {
  value = azurerm_kubernetes_cluster.akscluster.node_resource_group
}

# Managed Identities created for Addons

output "kubelet_id" {
  value = azurerm_kubernetes_cluster.akscluster.kubelet_identity[0].object_id
}

output "agic_id" {
  value = azurerm_kubernetes_cluster.akscluster.ingress_application_gateway[0].ingress_application_gateway_identity[0].object_id
}