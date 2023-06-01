#  Built-in 'Kubernetes cluster pod security restricted standards for Linux-based workloads' Azure Policy for Kubernetes initiative definition
resource "azurerm_resource_group_policy_assignment" "aks_lx_workload" {
  name                 = "AKS pod security restricted standards for Linux workloads"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/95edb821-ddaf-4404-9732-666045e056b4"
  location             = "Global"

  parameters = <<PARAMS
    {
      "excludedNamespaces": {
        "value": [
          "kube-system",
          "gatekeeper-system",
          "azure-arc",
          "flux-system",
          "windows-gmsa-webhook-system"
        ]
      },
      "effect": {
        "value": "Audit"
      }
    }
PARAMS
}

#  Built-in 'Kubernetes clusters should be accessible only over HTTPS' Azure Policy for Kubernetes policy definition
resource "azurerm_resource_group_policy_assignment" "aks_https_access" {
  name                 = "AKS should be accessible only over HTTPS"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1a5b4dca-0b6f-4cf5-907c-56316bc1bf3d"
  location             = "Global"

  parameters = <<PARAMS
    {
      "excludedNamespaces": {
        "value": []
      },
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'Kubernetes clusters should use internal load balancers' Azure Policy for Kubernetes policy definition
resource "azurerm_resource_group_policy_assignment" "aks_internal_lb" {
  name                 = "AKS should use internal load balancers"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/3fc4dc25-5baf-40d8-9b05-7fe74c1bc64e"
  location             = "Global"

  parameters = <<PARAMS
    {
      "excludedNamespaces": {
        "value": []
      },
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'Kubernetes cluster containers should run with a read only root file system' Azure Policy for Kubernetes policy definition
resource "azurerm_resource_group_policy_assignment" "aks_ro_fs" {
  name                 = "AKS containers should run with a read only root file system"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/df49d893-a74c-421d-bc95-c663042e5b80"
  location             = "Global"

  parameters = <<PARAMS
    {
      "excludedNamespaces": {
        "value": [
          "kube-system",
          "gatekeeper-system",
          "azure-arc",
          "flux-system",
          "windows-gmsa-webhook-system",
          "simpleapp"
        ]
      },
      "excludedContainers": {
        "value": [
          "kured"
        ]
      },
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'AKS container CPU and memory resource limits should not exceed the specified limits
resource "azurerm_resource_group_policy_assignment" "aks_cpu_mem_limit" {
  name                 = "AKS CPU and memory resource limits should not exceed"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e345eecc-fa47-480f-9e88-67dcc122b164"
  location             = "Global"

  parameters = <<PARAMS
    {
      "cpuLimit": {
        "value": "500m"
      },
      "memoryLimit": {
        "value": "1024Mi"
      },
      "excludedNamespaces": {
        "value": [
          "kube-system",
          "gatekeeper-system",
          "azure-arc",
          "flux-system",
          "windows-gmsa-webhook-system"
        ]
      },
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'AKS containers should only use allowed images'
resource "azurerm_resource_group_policy_assignment" "aks_containers_allowed" {
  name                 = "AKS containers should only use allowed images"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/febd0533-8e55-448f-b837-bd0e06f16469"
  location             = "Global"

   parameters = <<PARAMS
    {
      "allowedContainerImagesRegex": {
        "value":
          "${var.acr_name}\\.azurecr\\.io/.+$|mcr\\.microsoft\\.com/.+$"
      },
      "excludedNamespaces": {
        "value": [
          "kube-system",
          "gatekeeper-system",
          "azure-arc",
          "windows-gmsa-webhook-system"
        ]
      },
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'Kubernetes cluster pod hostPath volumes should only use allowed host paths'
resource "azurerm_resource_group_policy_assignment" "aks_path_vol" {
  name                 = "AKS pod hostPath volumes should only use allowed host paths"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/098fc59e-46c7-4d99-9b16-64990e543d75"
  location             = "Global"

  parameters = <<PARAMS
    {
      "excludedNamespaces": {
        "value": [
          "kube-system",
          "gatekeeper-system",
          "azure-arc",
          "flux-system",
          "windows-gmsa-webhook-system"
        ]
      },
      "allowedHostPaths": {
        "value": {
          "paths":[]
         }
      },
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'Kubernetes clusters should not allow endpoint edit permissions of ClusterRole/system:aggregate-to-edit' 
resource "azurerm_resource_group_policy_assignment" "aks_ep_edit" {
  name                 = "AKS should not allow endpoint edit permissions"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/1ddac26b-ed48-4c30-8cc5-3a68c79b8001"
  location             = "Global"
}

#  Built-in 'Kubernetes clusters should not use the default namespace'
resource "azurerm_resource_group_policy_assignment" "aks_default_ns" {
  name                 = "AKS should not use the default namespace"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/9f061a12-e40d-4183-a00e-171812443373"
  location             = "Global"

  parameters = <<PARAMS
    {
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'Azure Kubernetes Service clusters should have Defender profile enabled'
resource "azurerm_resource_group_policy_assignment" "aks_defender" {
  name                 = "AKS should have Defender profile enabled"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a1840de2-8088-4ea8-b153-b4c723e9cb01"
  location             = "Global"
}

#  Built-in 'Azure Kubernetes Service Clusters should enable Azure Active Directory integration'
resource "azurerm_resource_group_policy_assignment" "aks_aad" {
  name                 = "AKS should enable Azure Active Directory integration"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/450d2877-ebea-41e8-b00c-e286317d21bf"
  location             = "Global"
}

#   Built-in 'Azure Kubernetes Service Clusters should have local authentication methods disabled'
resource "azurerm_resource_group_policy_assignment" "aks_local_auth" {
  name                 = "AKS should have local authentication methods disabled"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/993c2fcd-2b29-49d2-9eb0-df2c3a730c32"
  location             = "Global"

  parameters = <<PARAMS
    {
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'Azure Policy Add-on for Kubernetes service (AKS) should be installed and enabled on your clusters'
resource "azurerm_resource_group_policy_assignment" "aks_policy_addon" {
  name                 = "AKS Policy Add-on for Kubernetes service"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/0a15ec92-a229-4763-bb14-0ea34a568f8d"
  location             = "Global"
}

#  Built-in 'Kubernetes Services should be upgraded to a non-vulnerable Kubernetes version'
resource "azurerm_resource_group_policy_assignment" "aks_vulnerable" {
  name                 = "AKS should be upgraded to a non-vulnerable Kubernetes ver"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/fb893a29-21bb-418c-a157-e99480ec364c"
  location             = "Global"
}

#  Built-in 'Role-Based Access Control (RBAC) should be used on Kubernetes Services'
resource "azurerm_resource_group_policy_assignment" "aks_rbac" {
  name                 = "(RBAC) should be used on AKS"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/ac4a19c2-fa67-49b4-8ae5-0b2e78c49457"
  location             = "Global"
}

#  Built-in 'Azure Kubernetes Service Clusters should use managed identities'
resource "azurerm_resource_group_policy_assignment" "aks_msi" {
  name                 = "AKS should use managed identities"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/da6e2401-19da-4532-9141-fb8fbde08431"
  location             = "Global"
}

#  Built-in 'Kubernetes cluster Windows containers should not overcommit cpu and memory'
resource "azurerm_resource_group_policy_assignment" "aks_win_overcommit" {
  name                 = "AKS Windows containers should not overcommit"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/a2abc456-f0ae-464b-bd3a-07a3cdbd7fb1"
  location             = "Global"
}

#  Built-in 'Kubernetes cluster Windows containers should not run as ContainerAdministrator'
resource "azurerm_resource_group_policy_assignment" "aks_win_runas" {
  name                 = "AKS Windows containers should not run as ContainerAdministrator"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/5485eac0-7e8f-4964-998b-a44f4f0c1e75"
  location             = "Global"

  parameters = <<PARAMS
    {
      "effect": {
        "value": "Deny"
      }
    }
PARAMS
}

#  Built-in 'Kubernetes cluster Windows containers should only run with approved user and domain user group'
resource "azurerm_resource_group_policy_assignment" "aks_win_user_allowed" {
  name                 = "AKS Windows containers approved user and domain user group"
  resource_group_id    = var.resource_group_id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/5485eac0-7e8f-4964-998b-a44f4f0c1e75"
  location             = "Global"
}