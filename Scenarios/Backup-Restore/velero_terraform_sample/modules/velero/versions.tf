terraform {
  required_version = "> 0.13.0"
  required_providers {
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
      version = ">= 1.11.1"
    }
  }
}
