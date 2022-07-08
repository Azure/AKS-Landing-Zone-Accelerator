terraform {
  required_version = ">= 0.13.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = ">= 2.1.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      #version = ">= 2.51"
      version = ">= 3.3.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.1.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "kubernetes" {
  alias = "aks-module"
  host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
}


provider "helm" {
  alias = "aks-module"
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks.kube_config[0].cluster_ca_certificate)
  }

}
provider "kubernetes" {
  alias = "aksdr-module"
  host                   = data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].cluster_ca_certificate)
}


provider "helm" {
  alias = "aksdr-module"
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.aks_dr.kube_config[0].cluster_ca_certificate)
  }
}
