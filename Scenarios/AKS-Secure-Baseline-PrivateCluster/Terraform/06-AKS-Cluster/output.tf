output "aksClusterId" {
    value = azurerm_kubernetes_cluster.aks-cluster.id
}

output "aksClusterIdentityPrincipalId" {
    value = azurerm_kubernetes_cluster.aks-cluster.identity[0].principal_id  
}